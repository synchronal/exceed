defmodule Exceed.WorksheetTest do
  # @related [subject](lib/exceed/worksheet.ex)
  use Test.SimpleCase, async: true
  alias Exceed.Worksheet
  alias XmlQuery, as: Xq

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
  end

  # # #

  defp extract_cells(row) do
    row
    |> Xq.all("//c")
    |> Enum.map(fn cell ->
      case Xq.attr(cell, "t") do
        "inlineStr" ->
          %{
            cell: Xq.attr(cell, "r"),
            children: "is/t",
            text: Xq.find!(cell, "//is/t") |> Xq.text(),
            type: "inlineStr"
          }

        "n" ->
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
