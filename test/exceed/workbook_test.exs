defmodule Exceed.WorkbookTest do
  # @related [subject](lib/exceed/workbook.ex)
  use Test.SimpleCase, async: true

  alias Exceed.Workbook

  doctest Workbook

  describe "new" do
    test "produces a new workbook with no sheets" do
      assert %Workbook{creator: "person", sheets: []} == Workbook.new("person")
    end
  end
end
