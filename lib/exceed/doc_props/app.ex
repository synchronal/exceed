defmodule Exceed.DocProps.App do
  @moduledoc false

  def to_xml do
    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      XmlStream.empty_element("Properties", %{
        "xmlns" => "http://schemas.openxmlformats.org/officeDocument/2006/extended-properties",
        "xmlns:vt" => "http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"
      })
    ]
  end
end