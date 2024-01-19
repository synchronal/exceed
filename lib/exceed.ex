defmodule Exceed do
  # @related [tests](test/exceed_test.exs)
  @moduledoc """
  `Exceed` is a high-level stream-oriented library for generating Excel files.
  """

  def stream!(%Exceed.Workbook{} = wb) do
    [
      {Exceed.ContentType.to_xml(), "[Content_Types].xml"},
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
