defmodule Exceed.DocProps.CoreTest do
  # @related [subject](lib/exceed/doc_props/core.ex)
  use Test.SimpleCase, async: true
  alias Exceed.DocProps.Core
  alias XmlQuery, as: Xq

  describe "to_xml" do
    test "includes a creator tag" do
      xml = Core.to_xml("creator name") |> stream_to_xml()
      assert tag = Xq.find!(xml, "/cp:coreProperties/dc:creator")

      assert Xq.text(tag) == "creator name"
    end

    test "includes a created at tag" do
      xml = Core.to_xml("creator name") |> stream_to_xml()
      assert tag = Xq.find!(xml, "/cp:coreProperties/dcterms:created")

      assert Xq.attr(tag, "xsi:type") == "dcterms:W3CDTF"
      assert {:ok, created_at, 0} = Xq.text(tag) |> DateTime.from_iso8601()
      assert_recent(created_at)
    end

    test "includes a modified at tag" do
      xml = Core.to_xml("creator name") |> stream_to_xml()
      assert tag = Xq.find!(xml, "/cp:coreProperties/dcterms:modified")

      assert Xq.attr(tag, "xsi:type") == "dcterms:W3CDTF"
      assert {:ok, created_at, 0} = Xq.text(tag) |> DateTime.from_iso8601()
      assert_recent(created_at)
    end
  end
end
