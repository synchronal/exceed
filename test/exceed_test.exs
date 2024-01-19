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

    test "includes a docProps/app.xml", %{tmpdir: tmpdir} do
      filename = Exceed.Workbook.new("me") |> stream_to_file(tmpdir)
      {:ok, app} = extract_file(filename, "docProps/app.xml")

      assert Xq.find!(app, "/Properties")
    end

    test "includes a docProps/core.xml", %{tmpdir: tmpdir} do
      filename = Exceed.Workbook.new("me") |> stream_to_file(tmpdir)
      {:ok, app} = extract_file(filename, "docProps/core.xml")

      assert props = Xq.find!(app, "/cp:coreProperties")

      assert props |> Xq.find!("dc:creator") |> Xq.text() == "me"
      assert {:ok, created_at, _} = props |> Xq.find!("dcterms:created") |> Xq.text() |> DateTime.from_iso8601()
      assert_recent(created_at)

      assert props |> Xq.find!("cp:revision") |> Xq.text() == "0"
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
end
