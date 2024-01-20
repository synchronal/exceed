defmodule Exceed.DocProps.App do
  @moduledoc false
  alias XmlStream, as: Xs

  def to_xml do
    [
      Xs.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      Xs.element(
        "Properties",
        %{
          "xmlns" => Exceed.Namespace.extended_properties(),
          "xmlns:vt" => Exceed.Namespace.doc_props_vt()
        },
        []
      )
    ]
  end
end
