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
      |> Enum.map(fn {:zip_file, name, _info, _, _, _} -> name end)
      |> assert_eq([
        ~c"[Content_Types].xml",
        ~c"_rels/.rels",
        ~c"docProps/app.xml",
        ~c"docProps/core.xml",
        ~c"xl/_rels/workbook.xml.rels",
        ~c"xl/workbook.xml",
        ~c"xl/styles.xml",
        ~c"xl/sharedStrings.xml"
      ])

      assert {:ok, wb} = XlsxReader.open(filename)
      assert XlsxReader.sheet_names(wb) == []
    end

    test "includes a [Content_Types].xml", %{tmpdir: tmpdir} do
      filename = Exceed.Workbook.new("me") |> stream_to_file(tmpdir)
      {:ok, content_type} = extract_file(filename, "[Content_Types].xml")

      assert [rels, xml] =
               Xq.find!(content_type, "/Types")
               |> Xq.all("Default")

      assert Xq.attr(rels, "Extension") == "rels"
      assert Xq.attr(rels, "ContentType") == "application/vnd.openxmlformats-package.relationships+xml"

      assert Xq.attr(xml, "Extension") == "xml"
      assert Xq.attr(xml, "ContentType") == "application/xml"

      assert [wb, app, core, wb_rels, styles, strings] =
               Xq.find!(content_type, "/Types")
               |> Xq.all("Override")

      assert Xq.attr(wb, "PartName") == "/xl/workbook.xml"
      assert Xq.attr(wb, "ContentType") == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"

      assert Xq.attr(app, "PartName") == "/docProps/app.xml"
      assert Xq.attr(app, "ContentType") == "application/vnd.openxmlformats-officedocument.extended-properties+xml"

      assert Xq.attr(core, "PartName") == "/docProps/core.xml"
      assert Xq.attr(core, "ContentType") == "application/vnd.openxmlformats-package.core-properties+xml"

      assert Xq.attr(wb_rels, "PartName") == "/xl/_rels/workbook.xml.rels"
      assert Xq.attr(wb_rels, "ContentType") == "application/vnd.openxmlformats-package.relationships+xml"

      assert Xq.attr(styles, "PartName") == "/xl/styles.xml"
      assert Xq.attr(styles, "ContentType") == "application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"

      assert Xq.attr(strings, "PartName") == "/xl/sharedStrings.xml"

      assert Xq.attr(strings, "ContentType") ==
               "application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"
    end

    test "includes a _rels/.rels", %{tmpdir: tmpdir} do
      filename = Exceed.Workbook.new("me") |> stream_to_file(tmpdir)
      {:ok, relationships} = extract_file(filename, "_rels/.rels")

      assert [wb, core, app] =
               Xq.find!(relationships, "/Relationships")
               |> Xq.all("Relationship")

      assert Xq.attr(wb, "Target") == "xl/workbook.xml"
      assert Xq.attr(wb, "Type") == "http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"
      assert Xq.attr(wb, "Id") == "rId1"

      assert Xq.attr(core, "Target") == "docProps/core.xml"

      assert Xq.attr(core, "Type") ==
               "http://schemas.openxmlformats.org/officeDocument/2006/relationships/metadata/core-properties"

      assert Xq.attr(core, "Id") == "rId2"

      assert Xq.attr(app, "Target") == "docProps/app.xml"

      assert Xq.attr(app, "Type") ==
               "http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties"

      assert Xq.attr(app, "Id") == "rId3"
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

    test "includes a xl/_rels/workbook.xml.rels", %{tmpdir: tmpdir} do
      filename = Exceed.Workbook.new("me") |> stream_to_file(tmpdir)
      {:ok, relationships} = extract_file(filename, "xl/_rels/workbook.xml.rels")

      assert [style, strings] =
               Xq.find!(relationships, "/Relationships")
               |> Xq.all("Relationship")

      assert Xq.attr(style, "Target") == "styles.xml"
      assert Xq.attr(style, "Type") == "http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"
      assert Xq.attr(style, "Id") == "rId1"

      assert Xq.attr(strings, "Target") == "sharedStrings.xml"

      assert Xq.attr(strings, "Type") ==
               "http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings"

      assert Xq.attr(strings, "Id") == "rId2"
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
          Exceed.Worksheet.new(
            "First Worksheet",
            ["Header A", "Header B", "Header C"],
            [["Content A1", "Content B1", "Content C1"], ["Content A2", "Content B2", "Content C2"]]
          )
        )
        |> Exceed.Workbook.add_worksheet(
          Exceed.Worksheet.new(
            "Second Worksheet",
            ["Header AA", "Header BB"],
            [["Content AA1", "Content BB1"], ["Content AA2", "Content BB2"]]
          )
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

    test "includes each sheet in the workbook relationships", %{filename: filename} do
      {:ok, relationships} = extract_file(filename, "xl/_rels/workbook.xml.rels")

      assert [style, strings, sheet_1, sheet_2] =
               Xq.find!(relationships, "/Relationships")
               |> Xq.all("Relationship")

      assert Xq.attr(style, "Target") == "styles.xml"
      assert Xq.attr(style, "Id") == "rId1"
      assert Xq.attr(strings, "Target") == "sharedStrings.xml"
      assert Xq.attr(strings, "Id") == "rId2"

      assert Xq.attr(sheet_1, "Target") == "worksheets/sheet1.xml"
      assert Xq.attr(sheet_1, "Type") == "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"
      assert Xq.attr(sheet_1, "Id") == "rId3"

      assert Xq.attr(sheet_2, "Target") == "worksheets/sheet2.xml"
      assert Xq.attr(sheet_2, "Type") == "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"
      assert Xq.attr(sheet_2, "Id") == "rId4"
    end
  end
end
