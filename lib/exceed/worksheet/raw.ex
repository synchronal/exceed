defmodule Exceed.Worksheet.Raw do
  @moduledoc """
  Generates SpreadsheetML XML directly as iodata, bypassing the
  `Exceed.Worksheet.Cell` protocol and `XmlStream` for improved performance
  on large data sets.

  Used internally by `Exceed.Worksheet.to_xml/1` when the `raw: true` option
  is set. Row data is processed in parallel batches via `Task.async_stream`.

  Supported value types: strings, integers, floats, booleans, atoms, `nil`,
  `Date`, `DateTime`, and `NaiveDateTime`.
  """

  @raw_batch_size 5_000

  def stream(%Exceed.Worksheet{headers: headers, content: content, opts: opts}) do
    %{col_padding: col_padding, col_widths: col_widths} = Exceed.Worksheet.normalize_opts(opts)
    col_letters = column_letters(headers || Enum.at(content, 0))

    header_xml = header_xml(headers, col_padding, col_widths)
    footer_xml = footer_xml()

    row_stream =
      content
      |> Exceed.Worksheet.prepend_headers(headers)
      |> Stream.with_index(1)
      |> Stream.chunk_every(@raw_batch_size)
      |> Task.async_stream(
        fn batch ->
          Enum.map(batch, fn {row, row_idx} ->
            row(row, row_idx, col_letters)
          end)
        end,
        ordered: true,
        max_concurrency: System.schedulers_online()
      )
      |> Stream.map(fn {:ok, rows} -> rows end)

    Stream.concat([
      [header_xml],
      row_stream,
      [footer_xml]
    ])
  end

  # # #

  defp column_letters(items) do
    items
    |> Enum.with_index()
    |> Enum.map(fn {_, i} -> col_idx_to_letter(i + 1) end)
  end

  defp col_idx_to_letter(n) when n <= 26, do: <<n + ?A - 1>>

  defp col_idx_to_letter(n) do
    col_idx_to_letter(div(n - 1, 26)) <> <<rem(n - 1, 26) + ?A>>
  end

  defp header_xml(headers, col_padding, col_widths) do
    cols_xml = cols_xml(headers, col_padding, col_widths)

    [
      ~s(<?xml version="1.0" encoding="UTF-8"?>),
      ~s(<worksheet xmlns="#{Exceed.Namespace.main()}" xmlns:r="#{Exceed.Namespace.relationships()}" xml:space="preserve">),
      ~s(<sheetPr><pageSetUpPr fitToPage="0"/></sheetPr>),
      ~s(<sheetViews><sheetView defaultGridColor="1" rightToLeft="0" showFormulas="0" showGridLines="1" showOutlineSymbols="0" showRowColHeaders="1" showRuler="1" showWhiteSpace="0" showZeros="1" tabSelected="0" windowProtection="0" workbookViewId="0" zoomScale="100" zoomScaleNormal="0" zoomScalePageLayoutView="0" zoomScaleSheetLayoutView="0"/></sheetViews>),
      ~s(<sheetFormatPr baseColWidth="8" defaultRowHeight="18"/>),
      cols_xml,
      ~s(<sheetData>)
    ]
  end

  defp cols_xml(nil, _padding, _widths), do: ""

  defp cols_xml(headers, padding, widths) do
    cols =
      headers
      |> Enum.with_index(1)
      |> Enum.map(fn {header, i} ->
        width = Map.get(widths, i, String.length(to_string(header)) + padding)
        ~s(<col min="#{i}" max="#{i}" width="#{width}"/>)
      end)

    ["<cols>", cols, "</cols>"]
  end

  defp footer_xml do
    [
      "</sheetData>",
      ~s(<sheetCalcPr fullCalcOnLoad="1"/>),
      ~s(<printOptions gridLines="0" headings="0" horizontalCentered="0" verticalCentered="0"/>),
      ~s(<pageMargins bottom="1.0" footer="0.5" header="0.5" left="0.75" right="0.75" top="1.0"/>),
      "<pageSetup/>",
      "<headerFooter/>",
      "</worksheet>"
    ]
  end

  defp row(cells, row_idx, col_letters) do
    row_str = Integer.to_string(row_idx)

    [
      "<row r=\"",
      row_str,
      "\">",
      cells(cells, row_str, col_letters),
      "</row>"
    ]
  end

  defp cells(cells, row_str, col_letters) do
    cells
    |> Enum.zip(col_letters)
    |> Enum.map(fn {value, letter} -> cell(value, letter, row_str) end)
  end

  defp cell(value, letter, row_str) when is_integer(value) do
    ["<c r=\"", letter, row_str, "\" t=\"n\"><v>", Integer.to_string(value), "</v></c>"]
  end

  defp cell(value, letter, row_str) when is_float(value) do
    ["<c r=\"", letter, row_str, "\" t=\"n\"><v>", Float.to_string(value), "</v></c>"]
  end

  defp cell(value, letter, row_str) when is_binary(value) do
    ["<c r=\"", letter, row_str, "\" t=\"inlineStr\"><is><t>", escape_xml(value), "</t></is></c>"]
  end

  defp cell(nil, letter, row_str) do
    ["<c r=\"", letter, row_str, "\" t=\"inlineStr\"><is><t></t></is></c>"]
  end

  defp cell(true, letter, row_str) do
    ["<c r=\"", letter, row_str, "\" t=\"b\"><v>1</v></c>"]
  end

  defp cell(false, letter, row_str) do
    ["<c r=\"", letter, row_str, "\" t=\"b\"><v>0</v></c>"]
  end

  defp cell(value, letter, row_str) when is_atom(value) do
    cell(Atom.to_string(value), letter, row_str)
  end

  defp cell(%Date{year: year} = date, letter, row_str) when year >= 1900 do
    value = Exceed.Util.to_excel_datetime(date)
    ["<c r=\"", letter, row_str, "\" s=\"1\"><v>", Float.to_string(value), "</v></c>"]
  end

  defp cell(%Date{} = date, letter, row_str) do
    cell(Date.to_iso8601(date), letter, row_str)
  end

  defp cell(%DateTime{year: year} = dt, letter, row_str) when year >= 1900 do
    value = Exceed.Util.to_excel_datetime(dt)
    ["<c r=\"", letter, row_str, "\" s=\"2\"><v>", Float.to_string(value), "</v></c>"]
  end

  defp cell(%DateTime{} = dt, letter, row_str) do
    cell(DateTime.to_iso8601(dt), letter, row_str)
  end

  defp cell(%NaiveDateTime{year: year} = ndt, letter, row_str) when year >= 1900 do
    value = Exceed.Util.to_excel_datetime(ndt)
    ["<c r=\"", letter, row_str, "\" s=\"2\"><v>", Float.to_string(value), "</v></c>"]
  end

  defp cell(%NaiveDateTime{} = ndt, letter, row_str) do
    cell(NaiveDateTime.to_iso8601(ndt), letter, row_str)
  end

  defp escape_xml(string) do
    string
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
