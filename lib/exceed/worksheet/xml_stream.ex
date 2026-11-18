defmodule Exceed.Worksheet.XmlStream do
  # @related [tests](test/exceed/worksheet/xml_stream_test.exs)

  @moduledoc false

  import Exceed.Util.Guards, only: [is_valid_year?: 1]
  alias Exceed.Util
  alias Exceed.Worksheet
  alias Exceed.Worksheet.Cell
  alias XmlStream, as: Xs

  def stream(%Worksheet{headers: headers, content: content}, opts) do
    opts = Map.put_new(opts, :row_heights, %{})

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
      sheet_data(content, headers, opts),
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

  defp cols(headers, padding, widths) do
    Xs.element(
      "cols",
      for {header, i} <- Enum.with_index(headers, 1) do
        width = Map.get(widths, i, String.length(to_string(header)) + padding)
        Xs.empty_element("col", %{"min" => i, "max" => i, "width" => width})
      end
    )
  end

  defp precompute_letters(count), do: for(index <- 1..count//1, do: Worksheet.column_name(index))

  defp prepend_headers(stream, nil), do: stream
  defp prepend_headers(stream, headers), do: Stream.concat([headers], stream)

  defp sheet_data(stream, headers, opts) do
    stream
    |> prepend_headers(headers)
    |> Stream.transform(
      fn -> {1, nil} end,
      fn
        row, {1, nil} ->
          letters = precompute_letters(length(row))
          {xml, next} = to_row(row, 1, letters, opts)
          {[sheet_start(row, opts), xml], {next, letters}}

        row, {index, letters} ->
          {xml, next} = to_row(row, index, letters, opts)
          {xml, {next, letters}}
      end,
      fn
        {1, nil} = state -> {[sheet_start([], opts)], state}
        state -> {[], state}
      end,
      fn _ -> :ok end
    )
  end

  defp sheet_start(row, opts), do: [cols(row, opts.col_padding, opts.col_widths), {:open, "sheetData", []}]

  # # # cells

  defp to_cells(row, row_idx, letters, opts), do: to_cells(row, row_idx, letters, 1, [], opts)

  defp to_cells([], _row_idx, _letters, _position, acc, _opts), do: :lists.reverse(acc)

  defp to_cells([cell | rest], row_idx, [letter | letters_rest], position, acc, opts) do
    element = styled_cell(cell, letter, row_idx, opts)
    to_cells(rest, row_idx, letters_rest, position + 1, [element | acc], opts)
  end

  defp to_cells([cell | rest], row_idx, [], position, acc, opts) do
    element = styled_cell(cell, Worksheet.column_name(position), row_idx, opts)
    to_cells(rest, row_idx, [], position + 1, [element | acc], opts)
  end

  defp styled_cell(cell, letter, row_idx, %{style_registry: registry} = opts) when not is_nil(registry) do
    {cell, offset} = Exceed.Datetime.local(cell)
    xml = build_cell(cell, letter, row_idx)
    {cell_format, cell_style} = protocol_style(xml, opts)
    format = rule_value(opts.cell_formats, letter, row_idx) || cell_format
    style = rule_value(opts.cell_styles, letter, row_idx) || cell_style

    if format || style || offset || native_format(cell) == :datetime do
      id =
        Exceed.Stylesheet.register(opts.style_registry, format || native_format(cell), style, offset, opts.style_config)

      put_style(xml, id)
    else
      put_date_style(cell, xml, opts)
    end
  end

  # Low-level XML rendering works without a workbook's style registry.
  defp styled_cell(cell, letter, row_idx, _opts), do: build_cell(cell, letter, row_idx)

  # Resolve the default date style once per sheet, not once per date cell.
  defp put_date_style(%Date{year: year}, xml, %{date_style: id}) when is_valid_year?(year) and id != 1,
    do: put_style(xml, id)

  defp put_date_style(_cell, xml, _opts), do: xml

  defp protocol_style([{:open, "c", %{"s" => name}}, _, _], opts) when is_atom(name) and name not in [nil, false],
    do: {nil, Map.fetch!(opts.style_config.styles, name)}

  # A numeric cellXfs index includes both the number format and appearance.
  defp protocol_style([{:open, "c", %{"s" => index}}, _, _], opts) do
    index = if is_binary(index), do: String.to_integer(index), else: index

    case Map.fetch(opts.style_config.cell_xfs, index) do
      {:ok, names} -> names
      :error -> raise ArgumentError, "unknown cell style index: #{inspect(index)}"
    end
  end

  defp protocol_style(_xml, _opts), do: {nil, nil}

  defp native_format(%Date{year: year}) when is_valid_year?(year), do: :date
  defp native_format(%DateTime{year: year}) when is_valid_year?(year), do: :datetime
  defp native_format(%NaiveDateTime{year: year}) when is_valid_year?(year), do: :datetime
  defp native_format(_), do: nil

  defp rule_value(rules, letter, row_idx) do
    Map.get(rules, {letter, row_idx}, Map.get(rules, row_idx, Map.get(rules, letter)))
  end

  defp put_style({:raw, [tag, _style, content]}, id), do: {:raw, [tag, ~s' s="#{id}"', content]}

  defp put_style([{:open, "c", attrs}, content, closing], id),
    do: [{:open, "c", Map.put(attrs, "s", id)}, content, closing]

  # Keep the style separate so applying it never needs to parse serialized XML.
  defp raw_cell(letter, row_idx, content, style \\ ""),
    do: {:raw, [~s'<c r="#{letter}#{row_idx}"', style, content]}

  defp build_cell(cell, letter, row_idx) when is_integer(cell) do
    raw_cell(letter, row_idx, ~s' t="n"><v>#{Integer.to_string(cell)}</v></c>')
  end

  defp build_cell(cell, letter, row_idx) when is_float(cell) do
    raw_cell(letter, row_idx, ~s' t="n"><v>#{:erlang.float_to_binary(cell, [:short])}</v></c>')
  end

  defp build_cell(cell, letter, row_idx) when is_binary(cell) do
    raw_cell(letter, row_idx, ~s' t="inlineStr"><is><t>#{Exceed.Xml.escape_binary(cell)}</t></is></c>')
  end

  defp build_cell(nil, letter, row_idx), do: raw_cell(letter, row_idx, " />")

  defp build_cell(true, letter, row_idx), do: raw_cell(letter, row_idx, ~s' t="b"><v>1</v></c>')

  defp build_cell(false, letter, row_idx), do: raw_cell(letter, row_idx, ~s' t="b"><v>0</v></c>')

  defp build_cell(cell, letter, row_idx) when is_atom(cell),
    do: build_cell(Atom.to_string(cell), letter, row_idx)

  defp build_cell(%type{year: year} = date, letter, row_idx) when type in [Date, DateTime, NaiveDateTime] do
    value = Util.to_excel_datetime(date)

    if is_valid_year?(year) do
      style = if type == Date, do: ~s' s="1"', else: ~s' s="2"'
      raw_cell(letter, row_idx, ~s'><v>#{:erlang.float_to_binary(value, [:short])}</v></c>', style)
    else
      build_cell(value, letter, row_idx)
    end
  end

  if Code.ensure_loaded?(Decimal) do
    defp build_cell(%Decimal{} = cell, letter, row_idx) do
      raw_cell(letter, row_idx, ~s' t="n"><v>#{Decimal.to_string(cell)}</v></c>')
    end
  end

  defp build_cell(cell, letter, row_idx) do
    attrs = cell |> Cell.to_attrs() |> Map.new() |> Map.put("r", letter <> row_idx)
    Xs.element("c", attrs, Cell.to_content(cell))
  end

  # # # rows

  defp to_row(items, row_idx, letters, opts) do
    identifier = Integer.to_string(row_idx)
    height = Map.get(opts.row_heights, identifier)
    attrs = if height, do: ~s' ht="#{height}" customHeight="1"', else: ""

    {[
       {:raw, [~s'<row r="#{identifier}"#{attrs}>']},
       to_cells(items, identifier, letters, opts),
       {:raw, [~c'</row>']}
     ], row_idx + 1}
  end
end
