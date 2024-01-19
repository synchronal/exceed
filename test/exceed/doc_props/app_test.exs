defmodule Exceed.DocProps.AppTest do
  # @related [subject](lib/exceed/doc_props/app.ex)
  use Test.SimpleCase, async: true
  alias Exceed.DocProps.App
  alias XmlQuery, as: Xq

  describe "to_xml" do
    test "includes an empty Properties tag" do
      xml = App.to_xml() |> stream_to_xml()
      assert tag = Xq.find!(xml, "/Properties")

      assert Xq.all(tag, "/*/node()") == []
    end
  end
end
