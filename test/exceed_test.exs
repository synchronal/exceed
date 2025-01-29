defmodule ExceedTest do
  # @related [subject](lib/exceed.ex)
  use Test.SimpleCase, async: true
  alias XmlQuery, as: Xq

  doctest Exceed

  describe "stream! without worksheets" do
    setup [:make_tmpdir]

    test "converts a workbook to a zlib stream that can be streamed to a file", %{tmpdir: tmpdir} do
      filename = Path.join(tmpdir, "empty_workbook.xlsx")

      assert_that(Exceed.Workbook.new("me") |> Exceed.stream!() |> Stream.into(File.stream!(filename)) |> Stream.run(),
        changes: File.exists?(filename),
        from: false,
        to: true
      )

      assert {:ok, [{:zip_comment, _} | files]} = :zip.list_dir(String.to_charlist(filename))

      files
      |> Enum.map(fn {:zip_file, name, _info, _, _, _} -> to_string(name) end)
      |> assert_eq([
        "[Content_Types].xml",
        "_rels/.rels",
        "docProps/app.xml",
        "docProps/core.xml",
        "xl/_rels/workbook.xml.rels",
        "xl/workbook.xml",
        "xl/styles.xml",
        "xl/sharedStrings.xml"
      ])

      assert {:ok, wb} = XlsxReader.open(filename)
      assert XlsxReader.sheet_names(wb) == []
    end

    test "includes an xl/workbook.xml", %{tmpdir: tmpdir} do
      filename = Exceed.Workbook.new("me") |> stream_to_file(tmpdir)
      {:ok, wb} = extract_file(filename, "xl/workbook.xml")

      assert [sheets] =
               Xq.find!(wb, "/workbook")
               |> Xq.all("sheets")

      assert sheets |> to_string() == "<sheets/>"
    end
  end

  describe "stream! with worksheets" do
    setup [:make_tmpdir]

    setup %{tmpdir: tmpdir} do
      filename =
        Exceed.Workbook.new("me")
        |> Exceed.Workbook.add_worksheet(
          Exceed.Worksheet.new("First Worksheet", ["Header A", "Header B", "Header C"], [
            ["Content A1", "Content B1", "Content C1"],
            ["Content A2", "Content B2", "Content C2"]
          ])
        )
        |> Exceed.Workbook.add_worksheet(
          Exceed.Worksheet.new("Second Worksheet", ["Header AA", "Header BB"], [
            ["Content AA1", "Content BB1"],
            ["Content AA2", "Content BB2"]
          ])
        )
        |> stream_to_file(tmpdir)

      [filename: filename]
    end

    test "includes a part for each sheet", %{filename: filename} do
      assert {:ok, [{:zip_comment, _} | files]} = :zip.list_dir(filename)

      parts = files |> Enum.map(fn {:zip_file, name, _info, _, _, _} -> to_string(name) end)

      assert "xl/worksheets/sheet1.xml" in parts
      assert "xl/worksheets/sheet2.xml" in parts
    end

    test "can be parsed", %{filename: filename} do
      assert {:ok, wb} = XlsxReader.open(to_string(filename))
      assert XlsxReader.sheet_names(wb) == ["First Worksheet", "Second Worksheet"]
    end
  end

  describe "dates" do
    setup [:make_tmpdir]

    test "can be parsed", %{tmpdir: tmpdir} do
      today = Date.utc_today()

      stream =
        Stream.unfold(0, fn i -> {[Date.add(today, -i)], i + 1} end)
        |> Stream.take(100)

      filename =
        Exceed.Workbook.new("me")
        |> Exceed.Workbook.add_worksheet(Exceed.Worksheet.new("Sheet", nil, stream))
        |> stream_to_file(tmpdir)

      assert {:ok, wb} = XlsxReader.open(to_string(filename))
      assert XlsxReader.sheet_names(wb) == ["Sheet"]
      assert {:ok, rows} = XlsxReader.sheet(wb, "Sheet")

      assert Enum.take(rows, 5) == [
               [today],
               [Date.add(today, -1)],
               [Date.add(today, -2)],
               [Date.add(today, -3)],
               [Date.add(today, -4)]
             ]
    end
  end

  describe "datetimes" do
    setup [:make_tmpdir]

    test "can be parsed", %{tmpdir: tmpdir} do
      now = DateTime.utc_now()

      stream =
        Stream.unfold(0, fn i -> {[DateTime.add(now, -i, :day)], i + 1} end)
        |> Stream.take(100)

      filename =
        Exceed.Workbook.new("me")
        |> Exceed.Workbook.add_worksheet(Exceed.Worksheet.new("Sheet", nil, stream))
        |> stream_to_file(tmpdir)

      assert {:ok, wb} = XlsxReader.open(to_string(filename))
      assert XlsxReader.sheet_names(wb) == ["Sheet"]
      assert {:ok, rows} = XlsxReader.sheet(wb, "Sheet")

      parsed_now = now |> DateTime.truncate(:second) |> DateTime.to_naive()

      assert Enum.take(rows, 5) == [
               [parsed_now],
               [NaiveDateTime.add(parsed_now, -1, :day)],
               [NaiveDateTime.add(parsed_now, -2, :day)],
               [NaiveDateTime.add(parsed_now, -3, :day)],
               [NaiveDateTime.add(parsed_now, -4, :day)]
             ]
    end
  end

  describe "strings" do
    setup [:make_tmpdir]

    test "can be parsed", %{tmpdir: tmpdir} do
      stream =
        Stream.unfold(65, fn char -> {[to_string([char])], char + 1} end)
        |> Stream.take(10_000)

      filename =
        Exceed.Workbook.new("me")
        |> Exceed.Workbook.add_worksheet(Exceed.Worksheet.new("Sheet", nil, stream))
        |> stream_to_file(tmpdir)

      assert {:ok, wb} = XlsxReader.open(to_string(filename))
      assert XlsxReader.sheet_names(wb) == ["Sheet"]
      assert {:ok, rows} = XlsxReader.sheet(wb, "Sheet")

      assert Enum.take(rows, 6) == [["A"], ["B"], ["C"], ["D"], ["E"], ["F"]]
      assert Enum.take(Enum.drop(rows, 490), 6) == [["ȫ"], ["Ȭ"], ["ȭ"], ["Ȯ"], ["ȯ"], ["Ȱ"]]
    end
  end
end
