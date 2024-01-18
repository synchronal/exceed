defmodule Exceed.DocProps.App do
  @moduledoc false

  def to_xml do
    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      XmlStream.empty_element("Properties", %{
        "xmlns" => Exceed.Namespace.extended_properties(),
        "xmlns:vt" => Exceed.Namespace.doc_props_vt()
      })
    ]
  end
end
