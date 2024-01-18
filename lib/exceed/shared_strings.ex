defmodule Exceed.SharedStrings do
  @moduledoc false

  def to_xml do
    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      XmlStream.element("sst", %{"xmlns" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}, [])
    ]
  end
end
