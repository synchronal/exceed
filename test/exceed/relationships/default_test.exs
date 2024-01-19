defmodule Exceed.Relationships.DefaultTest do
  # @related [subject](lib/exceed/relationships/default.ex)
  use Test.SimpleCase, async: true
  alias Exceed.Relationships.Default
  alias XmlQuery, as: Xq

  describe "to_xml" do
    test "includes a relationship for the workbook" do
      xml = Default.to_xml() |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Relationships/Relationship[@Target='xl/workbook.xml']")

      assert Xq.attr(tag, "Type") ==
               "http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"

      assert Xq.attr(tag, "Id") == "rId1"
    end

    test "includes a relationship for the core doc properties" do
      xml = Default.to_xml() |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Relationships/Relationship[@Target='docProps/core.xml']")

      assert Xq.attr(tag, "Type") ==
               "http://schemas.openxmlformats.org/officeDocument/2006/relationships/metadata/core-properties"

      assert Xq.attr(tag, "Id") == "rId2"
    end

    test "includes a relationship for the app doc properties" do
      xml = Default.to_xml() |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Relationships/Relationship[@Target='docProps/app.xml']")

      assert Xq.attr(tag, "Type") ==
               "http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties"

      assert Xq.attr(tag, "Id") == "rId3"
    end
  end
end
