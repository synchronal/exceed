defmodule Exceed.Relationships.Default do
  @moduledoc false

  def to_file do
    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      XmlStream.element(
        "Relationships",
        %{"xmlns" => "http://schemas.openxmlformats.org/package/2006/relationships"},
        [
          XmlStream.empty_element("Relationship", %{
            "Target" => "xl/workbook.xml",
            "Type" => type("officeDocument"),
            "Id" => "rId1"
          }),
          XmlStream.empty_element("Relationship", %{
            "Target" => "docProps/core.xml",
            "Type" => type("metadata/core-properties"),
            "Id" => "rId2"
          }),
          XmlStream.empty_element("Relationship", %{
            "Target" => "docProps/app.xml",
            "Type" => type("extended-properties"),
            "Id" => "rId3"
          })
        ]
      )
    ]
    |> Exceed.File.file("_rels/.rels")
  end

  defp type(type),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/" <> type
end
