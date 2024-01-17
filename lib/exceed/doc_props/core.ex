defmodule Exceed.DocProps.Core do
  @moduledoc false

  def to_file(creator) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      XmlStream.element(
        "cp:coreProperties",
        %{
          "xmlns:cp" => "http://schemas.openxmlformats.org/package/2006/metadata/core-properties",
          "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
          "xmlns:dcmitype" => "http://purl.org/dc/dcmitype/",
          "xmlns:dcterms" => "http://purl.org/dc/terms/",
          "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
        },
        [
          XmlStream.element("dc:creator", XmlStream.content(creator)),
          XmlStream.element("dcterms:created", %{"xsi:type" => "dcterms:W3CDTF"}, XmlStream.content(now)),
          XmlStream.element("cp:revision", XmlStream.content("0"))
        ]
      )
    ]
    |> Exceed.File.file("docProps/core.xml")
  end
end
