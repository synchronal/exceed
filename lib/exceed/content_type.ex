defmodule Exceed.ContentType do
  @moduledoc false

  def to_xml(%Exceed.Workbook{worksheets: worksheets}) do
    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8"),
      XmlStream.element("Types", %{"xmlns" => Exceed.Namespace.content_types()}, [
        XmlStream.empty_element("Default", %{
          "ContentType" => "application/vnd.openxmlformats-package.relationships+xml",
          "Extension" => "rels"
        }),
        XmlStream.empty_element("Default", %{
          "ContentType" => "application/xml",
          "Extension" => "xml"
        }),
        XmlStream.empty_element("Override", %{
          "ContentType" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml",
          "PartName" => "/xl/workbook.xml"
        }),
        XmlStream.empty_element("Override", %{
          "ContentType" => "application/vnd.openxmlformats-officedocument.extended-properties+xml",
          "PartName" => "/docProps/app.xml"
        }),
        XmlStream.empty_element("Override", %{
          "ContentType" => "application/vnd.openxmlformats-package.core-properties+xml",
          "PartName" => "/docProps/core.xml"
        }),
        XmlStream.empty_element("Override", %{
          "ContentType" => "application/vnd.openxmlformats-package.relationships+xml",
          "PartName" => "/xl/_rels/workbook.xml.rels"
        }),
        XmlStream.empty_element("Override", %{
          "ContentType" => "application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml",
          "PartName" => "/xl/styles.xml"
        }),
        XmlStream.empty_element("Override", %{
          "ContentType" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml",
          "PartName" => "/xl/sharedStrings.xml"
        })
        | for {_worksheet, i} <- Enum.with_index(worksheets, 1) do
            XmlStream.empty_element("Override", %{
              "ContentType" => "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml",
              "PartName" => "/xl/worksheets/sheet#{i}.xml"
            })
          end
      ])
    ]
  end
end
