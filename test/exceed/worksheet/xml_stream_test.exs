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

    test "renders integers as numeric c tags" do
      stream = [[12]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1" t="n"><v>12</v></c>|)
    end

    test "renders floats as numeric c tags" do
      stream = [[5.78]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1" t="n"><v>5.78</v></c>|)
    end

    test "renders binaries as inline string c tags, escaping XML special characters" do
      stream = [["a < b & c"]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1" t="inlineStr"><is><t>a &lt; b &amp; c</t></is></c>|)
    end

    test "renders true as a boolean c tag with value 1" do
      stream = [[true]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1" t="b"><v>1</v></c>|)
    end

    test "renders false as a boolean c tag with value 0" do
      stream = [[false]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1" t="b"><v>0</v></c>|)
    end

    test "renders non-boolean atoms as inline string c tags" do
      stream = [[:something]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1" t="inlineStr"><is><t>something</t></is></c>|)
    end

    test "renders dates with valid years as styled numeric c tags" do
      stream = [[~D[2024-01-01]]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1" s="1"><v>45292.0</v></c>|)
    end

    test "renders pre-1900 dates as inline string c tags" do
      stream = [[~D[1899-01-01]]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1" t="inlineStr"><is><t>1899-01-01</t></is></c>|)
    end

    test "renders datetimes with valid years as styled numeric c tags" do
      stream = [[~U[2024-01-01 15:01:02Z]]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1" s="2"><v>45292.62571759259</v></c>|)
    end

    test "renders pre-1900 datetimes as inline string c tags" do
      stream = [[~U[1899-01-01 15:01:02Z]]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1" t="inlineStr"><is><t>1899-01-01T15:01:02Z</t></is></c>|)
    end

    test "renders naive datetimes with valid years as styled numeric c tags" do
      stream = [[~N[2024-01-01 15:01:02]]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1" s="2"><v>45292.62571759259</v></c>|)
    end

    test "renders pre-1900 naive datetimes as inline string c tags" do
      stream = [[~N[1899-01-01 15:01:02]]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1" t="inlineStr"><is><t>1899-01-01T15:01:02</t></is></c>|)
    end

    test "renders decimals as numeric c tags" do
      stream = [[Decimal.new("5.78")]]

      xml =
        Exceed.Worksheet.new("Sheet", nil, stream)
        |> Exceed.Worksheet.XmlStream.stream(%{col_padding: 0, col_widths: %{}})
        |> stream_to_xml()

      Xq.find!(xml, "/worksheet/sheetData/row[@r='1']/c")
      |> to_string()
      |> assert_eq(~s|<c r="A1" t="n"><v>5.78</v></c>|)
    end
  end
end
