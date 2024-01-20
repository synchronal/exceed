defmodule Exceed do
  # @related [tests](test/exceed_test.exs)
  @moduledoc """
  Exceed is a high-level stream-oriented library for generating Excel files.
  It may be useful when generating spreadsheets from data sets that exceed
  available memory—or exceed the memory that one wishes to devote to
  generating Excel files.

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
  Convert an `Exceed.Workbook` to a stream.
  """
  @spec stream!(Exceed.Workbook.t()) :: Enum.t()
  def stream!(%Exceed.Workbook{} = wb) do
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
    |> Enum.map(&to_file/1)
    |> Zstream.zip()
  end

  # # #

  defp to_file({xml, filename}),
    do: Exceed.File.file(xml, filename)

  defp worksheets_to_files(worksheets) do
    for {worksheet, i} <- Enum.with_index(worksheets, 1) do
      {Exceed.Worksheet.to_xml(worksheet), "xl/worksheets/sheet#{i}.xml"}
    end
  end
end
