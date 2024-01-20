defmodule Exceed.WorkbookTest do
  # @related [subject](lib/exceed/workbook.ex)
  use Test.SimpleCase, async: true

  alias Exceed.Workbook
  alias XmlQuery, as: Xq

  doctest Workbook

  describe "new" do
    test "produces a new workbook with no sheets" do
      assert %Workbook{creator: "person", worksheets: []} == Workbook.new("person")
    end
  end

  describe "to_xml" do
    @describetag :workbook

    @tag sheet: ["Uno", "Dos", "Tres"]
    test "includes a sheet tag per worksheet, with r:id starting at 3", %{wb: wb} do
      xml = Workbook.to_xml(wb) |> stream_to_xml()

      assert sheet1 = Xq.find!(xml, "/workbook/sheets/sheet[1]")
      assert Xq.attr(sheet1, "name") == "Uno"
      assert Xq.attr(sheet1, "sheetId") == "1"
      assert Xq.attr(sheet1, "r:id") == "rId3"

      assert sheet2 = Xq.find!(xml, "/workbook/sheets/sheet[2]")
      assert Xq.attr(sheet2, "name") == "Dos"
      assert Xq.attr(sheet2, "sheetId") == "2"
      assert Xq.attr(sheet2, "r:id") == "rId4"

      assert sheet3 = Xq.find!(xml, "/workbook/sheets/sheet[3]")
      assert Xq.attr(sheet3, "name") == "Tres"
      assert Xq.attr(sheet3, "sheetId") == "3"
      assert Xq.attr(sheet3, "r:id") == "rId5"
    end
  end

  describe "inspect" do
    @describetag :workbook

    test "shows empty sheets", %{wb: wb} do
      assert inspect(wb) == "#Exceed.Workbook<sheets: []>"
    end

    @tag sheet: ["Uno", "Dos", "Tres"]
    test "shows sheet names when present", %{wb: wb} do
      assert inspect(wb) == "#Exceed.Workbook<sheets: [\"Uno\", \"Dos\", \"Tres\"]>"
    end
  end
end
