defmodule Exceed.ContentType do
  @moduledoc false

  def to_file do
    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      XmlStream.element("Types", %{"xmlns" => "http://schemas.openxmlformats.org/package/2006/content-types"}, [
        XmlStream.empty_element("Default", %{
          "ContentType" => "application/vnd.openxmlformats-package.relationships+xml",
          "Extension" => "rels"
        }),
        XmlStream.empty_element("Default", %{
          "ContentType" => "application/xml",
          "Extension" => "xml"
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
          "ContentType" => "application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml",
          "PartName" => "/xl/styles.xml"
        }),
        XmlStream.empty_element("Override", %{
          "ContentType" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml",
          "PartName" => "/xl/workbook.xml"
        })
      ])
    ]
    |> Exceed.File.file("[Content_Types].xml")
  end
end
