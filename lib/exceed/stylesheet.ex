defmodule Exceed.Stylesheet do
  @moduledoc false

  def to_xml do
    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      XmlStream.element("styleSheet", %{"xmlns" => Exceed.Namespace.main()}, [
        XmlStream.element("numFmts", %{"count" => "0"}, []),
        XmlStream.element("fonts", %{"count" => "1"}, [
          XmlStream.empty_element("font")
        ]),
        XmlStream.element("fills", %{"count" => "0"}, []),
        XmlStream.element("borders", %{"count" => "1"}, [
          XmlStream.element("border", [])
        ]),
        XmlStream.element("cellXfs", %{"count" => "0"}, [])
      ])
    ]
  end
end
