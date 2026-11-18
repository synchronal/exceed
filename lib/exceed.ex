defmodule Exceed do
  # @related [tests](test/exceed_test.exs)
  @moduledoc """
  Exceed is a high-level stream-oriented library for generating Excel files,
  useful when generating spreadsheets from data sets that exceed available
  memory (or the memory that one wishes to devote to generating Excel files).

  ## Examples

  ``` elixir
  iex> rows = Stream.repeatedly(fn -> [:rand.uniform(), :rand.uniform()] end)
  iex> stream = Exceed.Workbook.new("creator name")
  ...>   |> Exceed.Workbook.add_worksheet(
  ...>     Exceed.Worksheet.new("Sheet", ["header a", "header b"], Enum.take(rows, 10)))
  ...>   |> Exceed.stream!()
  ...>
  iex> zip = stream |> Enum.to_list() |> IO.iodata_to_binary()
  iex> {:ok, package} = XlsxReader.open(zip, [source: :binary])
  iex> XlsxReader.sheet_names(package)
  ["Sheet"]
  ```
  """

  @doc """
  Convert an `Exceed.Workbook` to a stream. See `Exceed.Workbook.new/1`,
  `Exceed.Worksheet.new/4`, and `Exceed.Workbook.add_worksheet/2`.

  Options:

  - `:buffer` - `true` (default) or `false`.
  Formats, styles and cell rules are configured in `Exceed.Worksheet.new/4`.
  Number formats may include `{offset}`, e.g. `"yyyy-mm-dd hh:mm:ss {offset}"`.
  Each `DateTime` supplies its own local time and UTC offset. Naive datetimes
  keep their time and display no offset. Styles are collected while streaming
  and written after worksheets; rows are never accumulated.
  """
  @spec stream!(Exceed.Workbook.t(), keyword()) :: Enum.t()
  def stream!(%Exceed.Workbook{} = wb, opts \\ []) do
    opts = Keyword.validate!(opts, [:buffer])
    wb = Exceed.Workbook.finalize(wb)

    # Prepare and validate settings once, without consuming rows or allocating a registry.
    worksheets = for worksheet <- wb.worksheets, do: {worksheet, Exceed.Worksheet.prepare(worksheet)}

    registry_config =
      case worksheets do
        [{_, sheet_opts} | _] -> sheet_opts.style_config
        [] -> Exceed.Stylesheet.config([], [])
      end

    Stream.transform(
      [nil],
      fn -> Exceed.Stylesheet.open(registry_config) end,
      fn _, registry -> {files(wb, worksheets, opts, registry), registry} end,
      &Exceed.Stylesheet.close/1
    )
  end

  defp files(wb, worksheets, opts, registry) do
    entries =
      [
        {Exceed.ContentType.to_xml(wb), "[Content_Types].xml"},
        {Exceed.Relationships.Default.to_xml(), "_rels/.rels"},
        {Exceed.DocProps.App.to_xml(), "docProps/app.xml"},
        {Exceed.DocProps.Core.to_xml(wb.creator), "docProps/core.xml"},
        {Exceed.Relationships.Workbook.to_xml(wb), "xl/_rels/workbook.xml.rels"},
        {Exceed.Workbook.to_xml(wb), "xl/workbook.xml"},
        {Exceed.SharedStrings.to_xml(), "xl/sharedStrings.xml"}
        | worksheets_to_files(worksheets, registry)
      ] ++
        [
          {Stream.flat_map([nil], fn _ -> Exceed.Stylesheet.to_xml(registry) end), "xl/styles.xml"}
        ]

    entries
    |> Enum.map(fn {xml, filename} -> Exceed.File.file(xml, filename, opts) end)
    |> Zstream.zip()
  end

  # # #

  defp worksheets_to_files(worksheets, registry) do
    for {{worksheet, opts}, i} <- Enum.with_index(worksheets, 1) do
      date_style = Exceed.Stylesheet.register(registry, :date, nil, nil, opts.style_config)
      opts = %{opts | style_registry: registry, date_style: date_style}
      {Exceed.Worksheet.XmlStream.stream(worksheet, opts), "xl/worksheets/sheet#{i}.xml"}
    end
  end
end
