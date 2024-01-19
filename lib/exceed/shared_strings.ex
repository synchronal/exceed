defmodule Exceed.SharedStrings do
  @moduledoc false

  def to_xml do
    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8"),
      XmlStream.element("sst", %{"xmlns" => Exceed.Namespace.main()}, [])
    ]
  end
end
