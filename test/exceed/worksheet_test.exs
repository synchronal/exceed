defmodule Exceed.WorksheetTest do
  # @related [subject](lib/exceed/worksheet.ex)
  use Test.SimpleCase, async: true
  alias Exceed.Worksheet
  alias XmlQuery, as: Xq

  doctest Exceed.Worksheet

  setup do
    stream =
      Stream.unfold(1, fn
        100 -> nil
        row -> {["row #{row} cell 1", row, row * 1.5], row + 1}
      end)

    headers = ["inline strings", "integers", "floats"]

    [headers: headers, stream: stream]
  end

  describe "new" do
    test "captures inputs", %{headers: headers, stream: stream} do
      assert %Worksheet{name: "sheet", headers: ^headers, content: ^stream, opts: []} =
               Worksheet.new("sheet", headers, stream)
    end

    test "can set headers to nil", %{stream: stream} do
      assert %Worksheet{name: "sheet", headers: nil, content: ^stream, opts: []} =
               Worksheet.new("sheet", nil, stream)
    end

    test "raises when headers are set to an empty list", %{stream: stream} do
      assert_raise Exceed.Error, "Worksheet headers must be a list of items or nil", fn ->
        Worksheet.new("sheet", [], stream)
      end
    end
  end

  describe "to_xml" do
    test "generates rows for the headers and each member of the stream", %{headers: headers, stream: stream} do
      ws = Worksheet.new("sheet", headers, Enum.take(stream, 2))
      xml = Worksheet.to_xml(ws) |> stream_to_xml()

      assert [header_row, row_1, row_2] = Xq.all(xml, "/worksheet/sheetData/row")

      assert header_row |> Xq.attr("r") == "1"

      header_row
      |> extract_cells()
      |> assert_eq([
        %{type: "inlineStr", text: "inline strings", children: "is/t", cell: "A1"},
        %{type: "inlineStr", text: "integers", children: "is/t", cell: "B1"},
        %{type: "inlineStr", text: "floats", children: "is/t", cell: "C1"}
      ])

      row_1
      |> extract_cells()
      |> assert_eq([
        %{type: "inlineStr", text: "row 1 cell 1", children: "is/t", cell: "A2"},
        %{type: "n", text: "1", children: "v", cell: "B2"},
        %{type: "n", text: "1.5", children: "v", cell: "C2"}
      ])

      row_2
      |> extract_cells()
      |> assert_eq([
        %{type: "inlineStr", text: "row 2 cell 1", children: "is/t", cell: "A3"},
        %{type: "n", text: "2", children: "v", cell: "B3"},
        %{type: "n", text: "3.0", children: "v", cell: "C3"}
      ])
    end

    test "can generate rows when no headers are given", %{stream: stream} do
      ws = Worksheet.new("sheet", nil, Enum.take(stream, 1))
      xml = Worksheet.to_xml(ws) |> stream_to_xml()

      assert [row_1] = Xq.all(xml, "/worksheet/sheetData/row")

      row_1
      |> extract_cells()
      |> assert_eq([
        %{type: "inlineStr", text: "row 1 cell 1", children: "is/t", cell: "A1"},
        %{type: "n", text: "1", children: "v", cell: "B1"},
        %{type: "n", text: "1.5", children: "v", cell: "C1"}
      ])
    end

    test "configures each column as wide as the header plus some default padding",
         %{headers: headers, stream: stream} do
      ws = Worksheet.new("sheet", headers, Enum.take(stream, 0))
      xml = Worksheet.to_xml(ws) |> stream_to_xml()

      [header1, header2, header3] = headers

      assert [col1, col2, col3] = Xq.all(xml, "/worksheet/cols/col")

      assert String.length(header1) == 14
      assert Xq.attr(col1, "min") == "1"
      assert Xq.attr(col1, "max") == "1"
      assert Xq.attr(col1, "width") == "18.25"

      assert String.length(header2) == 8
      assert Xq.attr(col2, "min") == "2"
      assert Xq.attr(col2, "max") == "2"
      assert Xq.attr(col2, "width") == "12.25"

      assert String.length(header3) == 6
      assert Xq.attr(col3, "min") == "3"
      assert Xq.attr(col3, "max") == "3"
      assert Xq.attr(col3, "width") == "10.25"
    end

    test "can set the column width padding",
         %{headers: headers, stream: stream} do
      ws = Worksheet.new("sheet", headers, Enum.take(stream, 0), cols: [padding: 2.34])
      xml = Worksheet.to_xml(ws) |> stream_to_xml()

      [header1, header2, header3] = headers

      assert [col1, col2, col3] = Xq.all(xml, "/worksheet/cols/col")

      assert String.length(header1) == 14
      assert Xq.attr(col1, "width") == "16.34"

      assert String.length(header2) == 8
      assert Xq.attr(col2, "width") == "10.34"

      assert String.length(header3) == 6
      assert Xq.attr(col3, "width") == "8.34"
    end

    test "uses the first row of the stream to set column width when headers are not given",
         %{stream: stream} do
      ws = Worksheet.new("sheet", nil, Enum.take(stream, 2))
      xml = Worksheet.to_xml(ws) |> stream_to_xml()

      assert [col1, col2, col3] = Xq.all(xml, "/worksheet/cols/col")
      assert Xq.attr(col1, "width") == "16.25"
      assert Xq.attr(col2, "width") == "5.25"
      assert Xq.attr(col3, "width") == "7.25"
    end

    test "can specify the width of specific columns",
         %{headers: headers, stream: stream} do
      ws = Worksheet.new("sheet", headers, Enum.take(stream, 2), cols: [widths: %{1 => 7.325, 3 => 1.1}])
      xml = Worksheet.to_xml(ws) |> stream_to_xml()

      assert [col1, col2, col3] = Xq.all(xml, "/worksheet/cols/col")
      assert Xq.attr(col1, "width") == "7.325"
      assert Xq.attr(col2, "width") == "12.25"
      assert Xq.attr(col3, "width") == "1.1"
    end

    test "converts datetimes to excel timestamp floats for times after 1900" do
      ws = %Worksheet{
        name: "sheet",
        headers: nil,
        content: [[~U(2024-01-01 00:00:00Z)], [~U(1899-12-31 00:00:00Z)]],
        opts: []
      }

      xml = Worksheet.to_xml(ws) |> stream_to_xml()
      assert [row_1, row_2] = Xq.all(xml, "/worksheet/sheetData/row")

      row_1
      |> extract_cells()
      |> assert_eq([
        %{type: "n", text: "45292.0", children: "v", cell: "A1"}
      ])

      row_2
      |> extract_cells()
      |> assert_eq([
        %{type: "inlineStr", text: "1899-12-31T00:00:00Z", children: "is/t", cell: "A2"}
      ])
    end

    test "converts dates to excel timestamp floats for times after 1900" do
      ws = %Worksheet{
        name: "sheet",
        headers: nil,
        content: [[~D(2024-01-01)], [~D(1899-12-31)]],
        opts: []
      }

      xml = Worksheet.to_xml(ws) |> stream_to_xml()
      assert [row_1, row_2] = Xq.all(xml, "/worksheet/sheetData/row")

      row_1
      |> extract_cells()
      |> assert_eq([
        %{type: "n", text: "45292.0", children: "v", cell: "A1"}
      ])

      row_2
      |> extract_cells()
      |> assert_eq([
        %{type: "inlineStr", text: "1899-12-31", children: "is/t", cell: "A2"}
      ])
    end
  end

  # # #

  defp extract_cells(row) do
    row
    |> Xq.all("//c")
    |> Enum.map(fn cell ->
      case {Xq.attr(cell, "s"), Xq.attr(cell, "t")} do
        {_, "inlineStr"} ->
          %{
            cell: Xq.attr(cell, "r"),
            children: "is/t",
            text: Xq.find!(cell, "//is/t") |> Xq.text(),
            type: "inlineStr"
          }

        {nil, "n"} ->
          %{
            cell: Xq.attr(cell, "r"),
            children: "v",
            text: Xq.find!(cell, "//v") |> Xq.text(),
            type: "n"
          }

        {"" <> _, nil} ->
          %{
            cell: Xq.attr(cell, "r"),
            children: "v",
            text: Xq.find!(cell, "//v") |> Xq.text(),
            type: "n"
          }
      end
    end)
  end
end
