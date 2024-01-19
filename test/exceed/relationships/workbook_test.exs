defmodule Exceed.Relationships.WorkbookTest do
  # @related [subject](lib/exceed/relationships/workbook.ex)
  use Test.SimpleCase, async: true
  alias Exceed.Relationships.Workbook
  alias XmlQuery, as: Xq

  describe "to_xml" do
    @describetag :workbook

    test "includes a relationship for the styles", %{wb: wb} do
      xml = Workbook.to_xml(wb) |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Relationships/Relationship[@Target='styles.xml']")

      assert Xq.attr(tag, "Type") ==
               "http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"

      assert Xq.attr(tag, "Id") == "rId1"
    end

    test "includes a relationship for the shared strings", %{wb: wb} do
      xml = Workbook.to_xml(wb) |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Relationships/Relationship[@Target='sharedStrings.xml']")

      assert Xq.attr(tag, "Type") ==
               "http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings"

      assert Xq.attr(tag, "Id") == "rId2"
    end

    test "does not include relationships to sheets when none exit", %{wb: wb} do
      xml = Workbook.to_xml(wb) |> stream_to_xml()
      assert Xq.find(xml, "/Relationships/Relationship[@Target='worksheets/sheet1.xml']") == nil
    end

    @tag sheet: ["First sheet", "Second sheet"]
    test "includes a relationship for each worksheet", %{wb: wb} do
      xml = Workbook.to_xml(wb) |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Relationships/Relationship[@Target='worksheets/sheet1.xml']")

      assert Xq.attr(tag, "Type") ==
               "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"

      assert Xq.attr(tag, "Id") == "rId3"

      assert tag = Xq.find!(xml, "/Relationships/Relationship[@Target='worksheets/sheet2.xml']")

      assert Xq.attr(tag, "Type") ==
               "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"

      assert Xq.attr(tag, "Id") == "rId4"
    end
  end
end
