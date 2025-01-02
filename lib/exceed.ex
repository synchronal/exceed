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

  The only option at the moment is `buffer` which can be set to `true` (the default)
  or to `false` (which may be more performant in some situations).
  """
  @spec stream!(Exceed.Workbook.t(), keyword()) :: Enum.t()
  def stream!(%Exceed.Workbook{} = wb, opts \\ []) do
    wb = Exceed.Workbook.finalize(wb)

    [
      {Exceed.ContentType.to_xml(wb), "[Content_Types].xml"},
      {Exceed.Relationships.Default.to_xml(), "_rels/.rels"},
      {Exceed.DocProps.App.to_xml(), "docProps/app.xml"},
      {Exceed.DocProps.Core.to_xml(wb.creator), "docProps/core.xml"},
      {Exceed.Relationships.Workbook.to_xml(wb), "xl/_rels/workbook.xml.rels"},
      {Exceed.Workbook.to_xml(wb), "xl/workbook.xml"},
      {Exceed.Stylesheet.to_xml(), "xl/styles.xml"},
      {Exceed.SharedStrings.to_xml(), "xl/sharedStrings.xml"}
      | worksheets_to_files(wb.worksheets)
    ]
    |> Enum.map(&to_file(&1, opts))
    |> Zstream.zip()
  end

  # # #

  defp to_file({xml, filename}, opts),
    do: Exceed.File.file(xml, filename, opts)

  defp worksheets_to_files(worksheets) do
    for {worksheet, i} <- Enum.with_index(worksheets, 1) do
      {Exceed.Worksheet.to_xml(worksheet), "xl/worksheets/sheet#{i}.xml"}
    end
  end
end
