defmodule Exceed.DocProps.Core do
  @moduledoc false

  def to_xml(creator) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      XmlStream.element(
        "cp:coreProperties",
        %{
          "xmlns:cp" => Exceed.Namespace.core_props(),
          "xmlns:dc" => Exceed.Namespace.dublin_core(),
          "xmlns:dcmitype" => Exceed.Namespace.dublin_core_type(),
          "xmlns:dcterms" => Exceed.Namespace.dublin_core_terms(),
          "xmlns:xsi" => Exceed.Namespace.schema_instance()
        },
        [
          XmlStream.element("dc:creator", XmlStream.content(creator)),
          XmlStream.element("dcterms:created", %{"xsi:type" => "dcterms:W3CDTF"}, XmlStream.content(now)),
          XmlStream.element("cp:revision", XmlStream.content("0"))
        ]
      )
    ]
  end
end
