defmodule Exceed.Relationships.Workbook do
  @moduledoc false

  def to_xml do
    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      XmlStream.element("Relationships", %{"xmlns" => Exceed.Namespace.relationships()}, [
        XmlStream.empty_element("Relationship", %{
          "Target" => "styles.xml",
          "Type" => Exceed.Relationships.type("styles"),
          "Id" => "rId1"
        }),
        XmlStream.empty_element("Relationship", %{
          "Target" => "sharedStrings.xml",
          "Type" => Exceed.Relationships.type("sharedStrings"),
          "Id" => "rId2"
        })
      ])
    ]
  end
end
