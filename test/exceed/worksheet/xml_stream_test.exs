defmodule Exceed.Worksheet.XmlStreamTest do
  # @related [subject](lib/exceed/worksheet/xml_stream.ex)
  use Test.SimpleCase, async: true
  alias XmlQuery, as: Xq

  describe "cells" do
    test "renders nil as an empty c tag" do
      stream = [[nil]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1"/>|)
    end
  end
end
