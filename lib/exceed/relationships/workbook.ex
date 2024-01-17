defmodule Exceed.Relationships.Workbook do
  @moduledoc false

  def to_xml do
    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      XmlStream.element(
        "Relationships",
        %{"xmlns" => "http://schemas.openxmlformats.org/package/2006/relationships"},
        [
          XmlStream.empty_element("Relationship", %{
            "Target" => "styles.xml",
            "Type" => type("styles"),
            "Id" => "rId1"
          })
        ]
      )
    ]
  end

  defp type(type),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/" <> type
end
