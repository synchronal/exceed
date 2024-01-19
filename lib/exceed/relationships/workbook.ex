defmodule Exceed.Relationships.Workbook do
  @moduledoc false

  alias XmlStream, as: Xs

  def to_xml(%Exceed.Workbook{worksheets: sheets}) do
    [
      Xs.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      Xs.element("Relationships", %{"xmlns" => Exceed.Namespace.relationships()}, [
        Xs.empty_element("Relationship", %{
          "Target" => "styles.xml",
          "Type" => Exceed.Relationships.type("styles"),
          "Id" => "rId1"
        }),
        Xs.empty_element("Relationship", %{
          "Target" => "sharedStrings.xml",
          "Type" => Exceed.Relationships.type("sharedStrings"),
          "Id" => "rId2"
        })
        | for {_sheet, idx} <- Enum.with_index(sheets, 1) do
            Xs.empty_element("Relationship", %{
              "Target" => "worksheets/sheet#{idx}.xml",
              "Type" => Exceed.Relationships.type("worksheet"),
              "Id" => "rId#{sheet_index(idx)}"
            })
          end
      ])
    ]
  end

  def sheet_index(i), do: i + 2
end
