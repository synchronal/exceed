defmodule ExceedTest do
  # @related [subject](lib/exceed.ex)
  use Test.SimpleCase, async: true
  alias XmlQuery, as: Xq

  doctest Exceed

  describe "stream!" do
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
      |> assert_eq([~c"[Content_Types].xml", ~c"_rels/.rels", ~c"docProps/app.xml", ~c"docProps/core.xml"])

      # assert {:ok, _wb} = XlsxReader.open(filename)
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

      assert [app, core, styles, wb] =
               Xq.find!(content_type, "/Types")
               |> Xq.all("Override")

      assert Xq.attr(app, "PartName") == "/docProps/app.xml"
      assert Xq.attr(app, "ContentType") == "application/vnd.openxmlformats-officedocument.extended-properties+xml"

      assert Xq.attr(core, "PartName") == "/docProps/core.xml"
      assert Xq.attr(core, "ContentType") == "application/vnd.openxmlformats-package.core-properties+xml"

      assert Xq.attr(styles, "PartName") == "/xl/styles.xml"
      assert Xq.attr(styles, "ContentType") == "application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"

      assert Xq.attr(wb, "PartName") == "/xl/workbook.xml"
      assert Xq.attr(wb, "ContentType") == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"
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
  end
end
