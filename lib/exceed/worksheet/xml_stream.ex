defmodule Exceed.Worksheet.XmlStream do
  @moduledoc false

  import Exceed.Util.Guards, only: [is_valid_year?: 1]
  alias Exceed.Util
  alias Exceed.Worksheet
  alias Exceed.Worksheet.Cell
  alias XmlStream, as: Xs

  def stream(%Worksheet{headers: headers, content: content}, %{col_padding: col_padding, col_widths: col_widths}) do
    resolved_headers = resolve_headers(headers, content)
    letters = precompute_letters(length(resolved_headers))

    [
      Xs.declaration(version: "1.0", encoding: "UTF-8"),
      {:open, "worksheet",
       %{"xmlns" => Exceed.Namespace.main(), "xmlns:r" => Exceed.Namespace.relationships(), "xml:space" => "preserve"}},
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
      cols(resolved_headers, col_padding, col_widths),
      {:open, "sheetData", []},
      sheet_data(content, headers, letters),
      {:close, "sheetData"},
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
      Xs.empty_element("headerFooter"),
      {:close, "worksheet"}
    ]
  end

  # # #

  defp cell_idx_to_letter(x), do: IO.chardata_to_string(:lists.reverse(x))

  defp cols(headers, padding, widths) do
    Xs.element(
      "cols",
      for {header, i} <- Enum.with_index(headers, 1) do
        width = Map.get(widths, i, String.length(to_string(header)) + padding)
        Xs.empty_element("col", %{"min" => i, "max" => i, "width" => width})
      end
    )
  end

  defp next_alphabet([x | rest]) when x >= ?A and x < ?Z, do: [x + 1 | rest]
  defp next_alphabet([]), do: [?A]
  defp next_alphabet([x | rest]) when x == ?Z, do: [?A | next_alphabet(rest)]

  defp precompute_letters(0), do: []

  defp precompute_letters(count) do
    {letters, _} =
      Enum.map_reduce(1..count, [?A], fn _, position ->
        {cell_idx_to_letter(position), next_alphabet(position)}
      end)

    letters
  end

  defp prepend_headers(stream, nil), do: stream
  defp prepend_headers(stream, headers), do: Stream.concat([headers], stream)

  defp resolve_headers(nil, content) do
    case content |> Stream.take(1) |> Enum.to_list() do
      [headers] -> headers
    end
  end

  defp resolve_headers(headers, _content), do: headers

  defp sheet_data(stream, headers, letters) do
    stream
    |> prepend_headers(headers)
    |> Stream.transform(1, fn row, row_idx ->
      to_row(row, row_idx, letters)
    end)
  end

  # # # cells

  defp to_cells(row, row_idx, letters), do: to_cells(row, row_idx, letters, [?A], [])

  defp to_cells([], _row_idx, _letters, _position, acc), do: :lists.reverse(acc)

  defp to_cells([cell | rest], row_idx, [letter | letters_rest], position, acc) do
    element = build_cell(cell, letter, row_idx)
    to_cells(rest, row_idx, letters_rest, next_alphabet(position), [element | acc])
  end

  defp to_cells([cell | rest], row_idx, [], position, acc) do
    element = build_cell(cell, cell_idx_to_letter(position), row_idx)
    to_cells(rest, row_idx, [], next_alphabet(position), [element | acc])
  end

  defp build_cell(cell, letter, row_idx) when is_integer(cell) do
    {:raw, [~s'<c r="#{letter}#{row_idx}" t="n"><v>#{Integer.to_string(cell)}</v></c>']}
  end

  defp build_cell(cell, letter, row_idx) when is_float(cell) do
    {:raw, [~s'<c r="#{letter}#{row_idx}" t="n"><v>#{:erlang.float_to_binary(cell, [:short])}</v></c>']}
  end

  defp build_cell(cell, letter, row_idx) when is_binary(cell) do
    {:raw, [~s'<c r="#{letter}#{row_idx}" t="inlineStr"><is><t>#{Exceed.Xml.escape_binary(cell)}</t></is></c>']}
  end

  defp build_cell(nil, letter, row_idx),
    do: {:raw, [~s'<c r="#{letter}#{row_idx}" s="3"/>']}

  defp build_cell(true, letter, row_idx),
    do: {:raw, [~s'<c r="#{letter}#{row_idx}" t="b"><v>1</v></c>']}

  defp build_cell(false, letter, row_idx),
    do: {:raw, [~s'<c r="#{letter}#{row_idx}" t="b"><v>0</v></c>']}

  defp build_cell(cell, letter, row_idx) when is_atom(cell),
    do:
      {:raw,
       [
         ~s'<c r="#{letter}#{row_idx}" t="inlineStr"><is><t>#{Exceed.Xml.escape_binary(Atom.to_string(cell))}</t></is></c>'
       ]}

  defp build_cell(%Date{year: year} = date, letter, row_idx) when is_valid_year?(year),
    do:
      {:raw,
       [
         ~s'<c r="#{letter}#{row_idx}" s="1"><v>#{:erlang.float_to_binary(Util.to_excel_datetime(date), [:short])}</v></c>'
       ]}

  defp build_cell(%Date{} = date, letter, row_idx),
    do:
      {:raw,
       [
         ~s'<c r="#{letter}#{row_idx}" t="inlineStr"><is><t>#{Util.to_excel_datetime(date)}</t></is></c>'
       ]}

  defp build_cell(%DateTime{year: year} = date, letter, row_idx) when is_valid_year?(year),
    do:
      {:raw,
       [
         ~s'<c r="#{letter}#{row_idx}" s="2"><v>#{:erlang.float_to_binary(Util.to_excel_datetime(date), [:short])}</v></c>'
       ]}

  defp build_cell(%DateTime{} = date, letter, row_idx),
    do:
      {:raw,
       [
         ~s'<c r="#{letter}#{row_idx}" t="inlineStr"><is><t>#{Util.to_excel_datetime(date)}</t></is></c>'
       ]}

  defp build_cell(%NaiveDateTime{year: year} = date, letter, row_idx) when is_valid_year?(year),
    do:
      {:raw,
       [
         ~s'<c r="#{letter}#{row_idx}" s="2"><v>#{:erlang.float_to_binary(Util.to_excel_datetime(date), [:short])}</v></c>'
       ]}

  defp build_cell(%NaiveDateTime{} = date, letter, row_idx),
    do:
      {:raw,
       [
         ~s'<c r="#{letter}#{row_idx}" t="inlineStr"><is><t>#{Util.to_excel_datetime(date)}</t></is></c>'
       ]}

  if Code.ensure_loaded?(Decimal) do
    defp build_cell(%Decimal{} = cell, letter, row_idx) do
      {:raw, [~s'<c r="#{letter}#{row_idx}" t="n"><v>#{Decimal.to_string(cell)}</v></c>']}
    end
  end

  defp build_cell(cell, letter, row_idx) do
    Xs.element("c", Map.put(Cell.to_attrs(cell), "r", letter <> row_idx), Cell.to_content(cell))
  end

  # # # rows

  defp to_row(items, row_idx, letters) do
    identifier = Integer.to_string(row_idx)

    {[
       {:raw, [~s'<row r="#{identifier}">']},
       to_cells(items, identifier, letters),
       {:raw, [~c'</row>']}
     ], row_idx + 1}
  end
end
