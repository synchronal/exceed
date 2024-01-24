defmodule Exceed.Worksheet.CellTest do
  # @related [subject](lib/exceed/worksheet/cell.ex)
  use Test.SimpleCase, async: true
  alias Exceed.Worksheet.Cell

  describe "floats" do
    test "attrs: assigns type of `n`" do
      assert Cell.to_attrs(5.78) == %{"t" => "n"}
    end

    test "content: wraps the content in `v`" do
      assert Cell.to_content(5.78) |> stream_to_xml() == "<v>5.78</v>"
    end
  end

  describe "integers" do
    test "attrs: assigns type of `n`" do
      assert Cell.to_attrs(12) == %{"t" => "n"}
    end

    test "content: wraps the content in `v`" do
      assert Cell.to_content(12) |> stream_to_xml() == "<v>12</v>"
    end
  end

  describe "strings" do
    test "attrs: assigns type of `inlineStr`" do
      assert Cell.to_attrs("Cell Content") == %{"t" => "inlineStr"}
    end

    test "content: wraps the content in `is`>`t`" do
      assert Cell.to_content("Cell Content") |> stream_to_xml() == "<is><t>Cell Content</t></is>"
    end
  end

  describe "dates" do
    test "attrs: assigns style of `1`" do
      assert Cell.to_attrs(~D[2024-01-01]) == %{"s" => "1"}
    end

    test "attrs: assigns type of `inlineStr` when before 1900" do
      assert Cell.to_attrs(~D[1899-01-01]) == %{"t" => "inlineStr"}
    end

    test "content: converts the date to epoch and wraps the content in `v`" do
      assert ~D[2024-01-01] |> Exceed.Util.to_excel_datetime() == 45_292.0
      assert Cell.to_content(~D[2024-01-01]) |> stream_to_xml() == "<v>45292.0</v>"
    end

    test "content: wraps the content in `is`>`t` when before 1900" do
      assert Cell.to_content(~D[1899-01-01]) |> stream_to_xml() == "<is><t>1899-01-01</t></is>"
    end
  end

  describe "utc datetimes" do
    test "attrs: assigns style of `2`" do
      assert Cell.to_attrs(~U[2024-01-01 15:01:02Z]) == %{"s" => "2"}
    end

    test "attrs: assigns type of `inlineStr` when before 1900" do
      assert Cell.to_attrs(~U[1899-01-01 23:59:59Z]) == %{"t" => "inlineStr"}
    end

    test "content: converts the date to epoch and wraps the content in `v`" do
      assert ~U[2024-01-01 15:01:02Z] |> Exceed.Util.to_excel_datetime() == 45_292.62571759259
      assert Cell.to_content(~U[2024-01-01 15:01:02Z]) |> stream_to_xml() == "<v>45292.62571759259</v>"
    end

    test "content: wraps the content in `is`>`t` tags when before 1900" do
      assert Cell.to_content(~U[1899-01-01 15:01:02Z]) |> stream_to_xml() == "<is><t>1899-01-01T15:01:02Z</t></is>"
    end
  end

  describe "decimals" do
    test "attrs: assigns type of `n`" do
      assert Cell.to_attrs(Decimal.new("5.78")) == %{"t" => "n"}
    end

    test "content: wraps the content in `v`" do
      assert Cell.to_content(Decimal.new("5.78")) |> stream_to_xml() == "<v>5.78</v>"
    end
  end
end
