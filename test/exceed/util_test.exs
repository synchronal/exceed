defmodule Exceed.UtilTest do
  # @related [subject](lib/exceed/util.ex)
  use Test.SimpleCase, async: true

  alias Exceed.Util

  describe "to_excel_datetime" do
    test "converts UTC datetimes to days since 1899, with seconds as fractional day" do
      assert ~U[1900-01-01 00:00:00Z] |> Util.to_excel_datetime() == 1.0
      assert ~U[1900-01-01 01:17:52Z] |> Util.to_excel_datetime() == 1.054074074074074
      assert (1 * 3600 + 17 * 60 + 52) / 86_400 == 0.05407407407407407

      assert ~U[1900-01-31 00:00:00Z] |> Util.to_excel_datetime() == 31.0
      assert ~U[1900-01-31 01:17:52Z] |> Util.to_excel_datetime() == 31.0540740740740742
    end

    test "corrects UTC datetimes for a bug in excel treating 1900 as a leap year" do
      assert ~U[1900-02-28 00:00:00Z] |> Util.to_excel_datetime() == 31 + 28
      assert ~U[1900-03-01 00:00:00Z] |> Util.to_excel_datetime() == 31 + 28 + 2
      assert ~U[2024-01-01 00:00:00Z] |> Util.to_excel_datetime() == 45_292.0
      assert (2024 - 1900) * 365 + 25 + 6 + 1 == 45_292
    end

    test "Converts UTC datetimes prior to 1900 to iso8601" do
      assert ~U[1899-12-31 23:59:59Z] |> Util.to_excel_datetime() == "1899-12-31T23:59:59Z"
    end

    test "converts naive datetimes to days since 1899, with seconds as fractional day" do
      assert ~N[1900-01-01 00:00:00] |> Util.to_excel_datetime() == 1.0
      assert ~N[1900-01-01 01:17:52] |> Util.to_excel_datetime() == 1.054074074074074
      assert (1 * 3600 + 17 * 60 + 52) / 86_400 == 0.05407407407407407

      assert ~N[1900-01-31 00:00:00] |> Util.to_excel_datetime() == 31.0
      assert ~N[1900-01-31 01:17:52] |> Util.to_excel_datetime() == 31.0540740740740742
    end

    test "corrects naive datetimes for a bug in excel treating 1900 as a leap year" do
      assert ~N[1900-02-28 00:00:00] |> Util.to_excel_datetime() == 31 + 28
      assert ~N[1900-03-01 00:00:00] |> Util.to_excel_datetime() == 31 + 28 + 2
      assert ~N[2024-01-01 00:00:00] |> Util.to_excel_datetime() == 45_292.0
      assert (2024 - 1900) * 365 + 25 + 6 + 1 == 45_292
    end

    test "Converts naive datetimes prior to 1900 to iso8601" do
      assert ~N[1899-12-31 23:59:59] |> Util.to_excel_datetime() == "1899-12-31T23:59:59"
    end

    test "converts a Date to days since 1899, with seconds as fractional day" do
      assert ~D[1900-01-01] |> Util.to_excel_datetime() == 1.0
      assert ~D[1900-01-31] |> Util.to_excel_datetime() == 31.0
    end

    test "corrects dates for a bug in excel treating 1900 as a leap year" do
      assert ~D[1900-02-28] |> Util.to_excel_datetime() == 31 + 28
      assert ~D[1900-03-01] |> Util.to_excel_datetime() == 31 + 28 + 2
      assert ~D[2024-01-01] |> Util.to_excel_datetime() == 45_292.0
    end

    test "Converts dates prior to 1900 to iso8601" do
      assert ~D[1899-12-31] |> Util.to_excel_datetime() == "1899-12-31"
    end
  end
end
