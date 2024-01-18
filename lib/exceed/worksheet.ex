defmodule Exceed.Worksheet do
  alias XmlStream, as: Xs

  @type headers() :: [String.t()] | nil
  @type t() :: %__MODULE__{
          content: Enum.t(),
          headers: headers(),
          name: String.t(),
          opts: keyword()
        }

  defstruct ~w(
    content
    headers
    name
    opts
  )a

  @spec new(String.t(), headers(), Enum.t(), keyword()) :: t()
  def new(name, headers, content, opts \\ []),
    do: __struct__(name: name, headers: headers, content: content, opts: opts)

  @doc false
  def to_xml(%__MODULE__{} = _worksheet) do
    [
      Xs.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      Xs.element(
        "worksheet",
        %{
          "xmlns" => Exceed.Namespace.main(),
          "xmlns:r" => Exceed.Namespace.relationships(),
          "xml:space" => "preserve"
        },
        [
          Xs.element("sheetPr", [Xs.empty_element("pageSetUpPr", %{"fitToPage" => "0"})]),
          Xs.element("sheetViews", [
            Xs.empty_element("sheetView", %{
              "windowProtection" => "0",
              "tabSelected" => "0",
              "showWhiteSpace" => "0",
              "showOutlineSymbols" => "0",
              "showFormulas" => "0",
              "rightToLeft" => "0",
              "showZeros" => "1",
              "showRuler" => "1",
              "showRowColHeaders" => "1",
              "showGridLines" => "1",
              "defaultGridColor" => "1",
              "zoomScale" => "100",
              "workbookViewId" => "0",
              "zoomScaleSheetLayoutView" => "0",
              "zoomScalePageLayoutView" => "0",
              "zoomScaleNormal" => "0"
            })
          ]),
          Xs.empty_element("sheetFormatPr", %{"baseColWidth" => "8", "defaultRowHeight" => "18"}),
          Xs.element("cols", []),
          Xs.element("sheetData", []),
          Xs.empty_element("printOptions", %{
            "verticalCentered" => "0",
            "horizontalCentered" => "0",
            "headings" => "0",
            "gridLines" => "0"
          }),
          Xs.empty_element("pageMargins", %{
            "right" => "0.75",
            "left" => "0.75",
            "bottom" => "1.0",
            "top" => "1.0",
            "footer" => "0.5",
            "header" => "0.5"
          }),
          Xs.empty_element("pageSetup"),
          Xs.empty_element("headerFooter")
        ]
      )
    ]
  end
end
