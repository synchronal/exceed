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
      {Exceed.Relationships.Workbook.to_xml(), "xl/_rels/workbook.xml.rels"},
      {Exceed.Workbook.to_xml(wb), "xl/workbook.xml"}
    ]
    |> Enum.map(&to_file/1)
    |> Zstream.zip()
  end

  # # #

  defp to_file({xml, filename}),
    do: Exceed.File.file(xml, filename)
end
