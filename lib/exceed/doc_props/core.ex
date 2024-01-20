defmodule Exceed.DocProps.Core do
  @moduledoc false
  alias XmlStream, as: Xs

  def to_xml(creator) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    [
      Xs.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      Xs.element(
        "cp:coreProperties",
        %{
          "xmlns:cp" => Exceed.Namespace.core_props(),
          "xmlns:dc" => Exceed.Namespace.dublin_core(),
          "xmlns:dcterms" => Exceed.Namespace.dublin_core_terms(),
          "xmlns:dcmitype" => Exceed.Namespace.dublin_core_type(),
          "xmlns:xsi" => Exceed.Namespace.schema_instance()
        },
        [
          # Xs.element("dc:title", Xs.content(title)),
          Xs.empty_element("dc:subject"),
          Xs.element("dc:creator", Xs.content(creator)),
          Xs.empty_element("cp:keywords"),
          Xs.empty_element("dc:description"),
          Xs.element("cp:lastModifiedBy", Xs.content(creator)),
          Xs.element("dcterms:created", %{"xsi:type" => "dcterms:W3CDTF"}, Xs.content(now)),
          Xs.element("dcterms:modified", %{"xsi:type" => "dcterms:W3CDTF"}, Xs.content(now)),
          Xs.element("cp:category", [])
        ]
      )
    ]
  end
end
