defmodule Exceed.Stylesheet do
  @moduledoc false

  alias XmlStream, as: Xs

  def to_xml do
    [
      Xs.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      Xs.element("styleSheet", %{"xmlns" => Exceed.Namespace.main()}, [
        Xs.element("numFmts", %{"count" => "2"}, [
          Xs.empty_element("numFmt", %{"numFmtId" => "164", "formatCode" => "yyyy-mm-dd"}),
          Xs.empty_element("numFmt", %{"numFmtId" => "165", "formatCode" => "yyyy-mm-dd hh:mm:ss"})
        ]),
        Xs.element("fonts", %{"count" => "1"}, [
          Xs.empty_element("font")
        ]),
        Xs.element("fills", %{"count" => "1"}, [
          Xs.element("fill", [Xs.empty_element("patternFill", %{"patternType" => "none"})])
        ]),
        Xs.element("borders", %{"count" => "1"}, [
          # Important: borders must be in order start/end/top/bottom/diagonal
          Xs.element("border", [
            Xs.empty_element("start"),
            Xs.empty_element("end"),
            Xs.empty_element("top"),
            Xs.empty_element("bottom"),
            Xs.empty_element("diagonal")
          ])
        ]),
        Xs.element("cellXfs", %{"count" => "3"}, [
          Xs.empty_element("xf", %{"borderId" => "0", "fontId" => "0", "numFmtId" => "0", "xfId" => "0"}),
          Xs.empty_element("xf", %{
            "numFmtId" => "164",
            "borderId" => "0",
            "fontId" => "0",
            "xfId" => "0",
            "applyNumberFormat" => "1"
          }),
          Xs.empty_element("xf", %{
            "numFmtId" => "165",
            "borderId" => "0",
            "fontId" => "0",
            "xfId" => "0",
            "applyNumberFormat" => "1"
          })
        ]),
        Xs.element(
          "tableStyles",
          %{"count" => "0", "defaultPivotStyle" => "PivotStyleLight16", "defaultTableStyle" => "TableStyleMedium9"},
          []
        )
      ])
    ]
  end
end
