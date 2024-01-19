defmodule Exceed.Stylesheet do
  @moduledoc false

  alias XmlStream, as: Xs

  def to_xml do
    [
      Xs.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      Xs.element("styleSheet", %{"xmlns" => Exceed.Namespace.main()}, [
        Xs.element("numFmts", %{"count" => "0"}, []),
        Xs.element("fonts", %{"count" => "1"}, [
          Xs.empty_element("font")
        ]),
        Xs.element("fills", %{"count" => "0"}, [
          Xs.element("fill", [
            Xs.empty_element("patternFill", %{"patternType" => "none"})
          ])
        ]),
        Xs.element("borders", %{"count" => "1"}, [
          Xs.element("border", [
            Xs.empty_element("bottom"),
            Xs.empty_element("diagonal"),
            Xs.empty_element("left"),
            Xs.empty_element("right"),
            Xs.empty_element("top")
          ])
        ]),
        Xs.element("cellXfs", %{"count" => "0"}, []),
        Xs.element(
          "tableStyles",
          %{"count" => "0", "defaultPivotStyle" => "PivotStyleLight16", "defaultTableStyle" => "TableStyleMedium9"},
          []
        )
      ])
    ]
  end
end
