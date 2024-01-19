defmodule Exceed.ContentTypeTest do
  # @related [subject](lib/exceed/content_type.ex)
  use Test.SimpleCase, async: true
  alias Exceed.ContentType
  alias XmlQuery, as: Xq

  describe "to_xml" do
    @describetag :workbook

    test "includes a default for extension: rels", %{wb: wb} do
      xml = ContentType.to_xml(wb) |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Types/Default[@Extension='rels']")

      assert to_string(tag) ==
               "<Default ContentType=\"application/vnd.openxmlformats-package.relationships+xml\" Extension=\"rels\"/>"
    end

    test "includes a default for extension: xml", %{wb: wb} do
      xml = ContentType.to_xml(wb) |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Types/Default[@Extension='xml']")

      assert to_string(tag) ==
               "<Default ContentType=\"application/xml\" Extension=\"xml\"/>"
    end

    test "includes an override for /xl/workbook.xml", %{wb: wb} do
      xml = ContentType.to_xml(wb) |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Types/Override[@PartName='/xl/workbook.xml']")
      assert Xq.attr(tag, "ContentType") == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"
    end

    test "includes an override for /docProps/app.xml", %{wb: wb} do
      xml = ContentType.to_xml(wb) |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Types/Override[@PartName='/docProps/app.xml']")
      assert Xq.attr(tag, "ContentType") == "application/vnd.openxmlformats-officedocument.extended-properties+xml"
    end

    test "includes an override for /docProps/core.xml", %{wb: wb} do
      xml = ContentType.to_xml(wb) |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Types/Override[@PartName='/docProps/core.xml']")
      assert Xq.attr(tag, "ContentType") == "application/vnd.openxmlformats-package.core-properties+xml"
    end

    test "includes an override for /xl/_rels/workbook.xml.rels", %{wb: wb} do
      xml = ContentType.to_xml(wb) |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Types/Override[@PartName='/xl/_rels/workbook.xml.rels']")
      assert Xq.attr(tag, "ContentType") == "application/vnd.openxmlformats-package.relationships+xml"
    end

    test "includes an override for /xl/styles.xml", %{wb: wb} do
      xml = ContentType.to_xml(wb) |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Types/Override[@PartName='/xl/styles.xml']")
      assert Xq.attr(tag, "ContentType") == "application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"
    end

    test "includes an override for /xl/sharedStrings.xml", %{wb: wb} do
      xml = ContentType.to_xml(wb) |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Types/Override[@PartName='/xl/sharedStrings.xml']")

      assert Xq.attr(tag, "ContentType") ==
               "application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"
    end

    test "does not include overrides for sheets when none exist", %{wb: wb} do
      xml = ContentType.to_xml(wb) |> stream_to_xml()

      assert Xq.find(xml, "/Types/Override[@PartName='/xl/worksheets/sheet1.xml']") == nil
    end

    @tag sheet: ["First", "Second"]
    test "includes an override for each worksheet", %{wb: wb} do
      xml = ContentType.to_xml(wb) |> stream_to_xml()

      assert tag = Xq.find!(xml, "/Types/Override[@PartName='/xl/worksheets/sheet1.xml']")
      assert Xq.attr(tag, "ContentType") == "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"

      assert tag = Xq.find!(xml, "/Types/Override[@PartName='/xl/worksheets/sheet2.xml']")
      assert Xq.attr(tag, "ContentType") == "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"
    end
  end
end
