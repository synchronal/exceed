defmodule Exceed.Relationships.Default do
  @moduledoc false

  def to_xml do
    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8"),
      XmlStream.element("Relationships", %{"xmlns" => Exceed.Namespace.relationships()}, [
        XmlStream.empty_element("Relationship", %{
          "Target" => "xl/workbook.xml",
          "Type" => Exceed.Relationships.type("officeDocument"),
          "Id" => "rId1"
        }),
        XmlStream.empty_element("Relationship", %{
          "Target" => "docProps/core.xml",
          "Type" => Exceed.Relationships.type("metadata/core-properties"),
          "Id" => "rId2"
        }),
        XmlStream.empty_element("Relationship", %{
          "Target" => "docProps/app.xml",
          "Type" => Exceed.Relationships.type("extended-properties"),
          "Id" => "rId3"
        })
      ])
    ]
  end
end
