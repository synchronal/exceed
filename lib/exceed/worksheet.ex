defmodule Exceed.Worksheet do
  # @related [tests](test/exceed/worksheet_test.exs)
  alias XmlStream, as: Xs

  @type headers() :: [String.t()] | nil
  @type spreadsheet_options() :: [spreadsheet_option()]
  @type spreadsheet_option() :: {:col_padding, float()}

  @type t() :: %__MODULE__{
          content: Enum.t(),
          headers: headers(),
          name: String.t(),
          opts: spreadsheet_options()
        }

  defstruct ~w(
    content
    headers
    name
    opts
  )a

  @spec new(String.t(), headers(), Enum.t(), keyword()) :: t()
  def new(name, headers, content, opts \\ [])

  def new(_name, [], _content, _opts),
    do: raise(Exceed.Error, "Worksheet headers must be a list of items or nil")

  def new(name, headers, content, opts),
    do: __struct__(name: name, headers: headers, content: content, opts: opts)

  @doc false
  def to_xml(%__MODULE__{headers: headers, content: content, opts: opts}) do
    [
      Xs.declaration(version: "1.0", encoding: "UTF-8"),
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
              "defaultGridColor" => "1",
              "rightToLeft" => "0",
              "showFormulas" => "0",
              "showGridLines" => "1",
              "showOutlineSymbols" => "0",
              "showRowColHeaders" => "1",
              "showRuler" => "1",
              "showWhiteSpace" => "0",
              "showZeros" => "1",
              "tabSelected" => "0",
              "windowProtection" => "0",
              "workbookViewId" => "0",
              "zoomScale" => "100",
              "zoomScaleNormal" => "0",
              "zoomScalePageLayoutView" => "0",
              "zoomScaleSheetLayoutView" => "0"
            })
          ]),
          Xs.empty_element("sheetFormatPr", %{"baseColWidth" => "8", "defaultRowHeight" => "18"}),
          cols(headers, content, opts),
          Xs.element("sheetData", sheet_data(content, headers)),
          Xs.empty_element("sheetCalcPr", %{"fullCalcOnLoad" => "1"}),
          Xs.empty_element("printOptions", %{
            "gridLines" => "0",
            "headings" => "0",
            "horizontalCentered" => "0",
            "verticalCentered" => "0"
          }),
          Xs.empty_element("pageMargins", %{
            "bottom" => "1.0",
            "footer" => "0.5",
            "header" => "0.5",
            "left" => "0.75",
            "right" => "0.75",
            "top" => "1.0"
          }),
          Xs.empty_element("pageSetup"),
          Xs.empty_element("headerFooter")
        ]
      )
    ]
  end

  # # #

  defp cols(nil, content, opts) do
    case content |> Stream.take(1) |> Enum.to_list() do
      [headers] -> cols(headers, content, opts)
    end
  end

  defp cols(headers, _content, opts) do
    padding = Keyword.get(opts, :col_padding, 4.25)

    Xs.element(
      "cols",
      for {header, i} <- Enum.with_index(headers, 1) do
        width = String.length(to_string(header)) + padding
        Xs.empty_element("col", %{"min" => i, "max" => i, "width" => width})
      end
    )
  end

  defp sheet_data(stream, headers) do
    stream
    |> prepend_headers(headers)
    |> Stream.transform(1, fn row, row_idx ->
      row(
        row,
        fn
          item when is_number(item) ->
            {%{"t" => "n"}, Xs.element("v", [Xs.content(to_string(item))])}

          item when is_binary(item) ->
            {%{"t" => "inlineStr"}, Xs.element("is", [Xs.element("t", [Xs.content(item)])])}
        end,
        row_idx
      )
    end)
  end

  defp row(items, mapper, row_index) do
    identifier = to_string(row_index)
    {[Xs.element("row", %{"r" => identifier}, cells(items, identifier, mapper))], row_index + 1}
  end

  defp cells(row, row_idx, mapper) do
    Enum.map_reduce(row, [65], fn cell, count ->
      {attrs, body} = mapper.(cell)
      cell_letter = cell_idx_to_letter(count)

      {Xs.element("c", Map.merge(attrs, %{"r" => cell_letter <> row_idx}), body), next_alphabet(count)}
    end)
    |> elem(0)
  end

  defp next_alphabet([x | rest]) when x >= 65 and x < 90, do: [x + 1 | rest]
  defp next_alphabet([]), do: [65]
  defp next_alphabet([x | rest]) when x == 90, do: [65 | next_alphabet(rest)]

  defp cell_idx_to_letter(x), do: IO.chardata_to_string(Enum.reverse(x))

  defp prepend_headers(stream, nil), do: stream
  defp prepend_headers(stream, headers), do: Stream.concat([headers], stream)
end
