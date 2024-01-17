defmodule ExceedTest do
  # @related [subject](lib/exceed.ex)
  use Test.SimpleCase, async: true
  alias XmlQuery, as: Xq

  doctest Exceed

  describe "stream!" do
    setup [:make_tmpdir]

    test "converts a workbook to a zlib stream that can be streamed to a file", %{tmpdir: tmpdir} do
      filename = Path.join(tmpdir, "empty_workbook.xlsx")

      assert_that(
        Exceed.Workbook.new()
        |> Exceed.stream!()
        |> Stream.into(File.stream!(filename))
        |> Stream.run(),
        changes: File.exists?(filename),
        from: false,
        to: true
      )

      assert {:ok, handle} = :zip.zip_open(String.to_charlist(filename), [:memory])
      assert {:ok, [{~c"[Content_Types].xml", _}]} = :zip.zip_get(handle)

      # assert {:ok, _wb} = XlsxReader.open(filename)
    end

    test "includes a [Content_Types].xml", %{tmpdir: tmpdir} do
      filename = Path.join(tmpdir, "empty_workbook.xlsx")

      Exceed.Workbook.new()
      |> Exceed.stream!()
      |> Stream.into(File.stream!(filename))
      |> Stream.run()

      assert {:ok, handle} = :zip.zip_open(String.to_charlist(filename), [:memory])
      {:ok, {_zip_name, content_type}} = :zip.zip_get(~c"[Content_Types].xml", handle)

      assert [rels, core] =
               Xq.find!(content_type, "/Types")
               |> Xq.all("//Default")

      assert Xq.attr(rels, "ContentType") == "application/vnd.openxmlformats-package.relationships+xml"
      assert Xq.attr(rels, "Extension") == "rels"

      assert Xq.attr(core, "ContentType") == "application/xml"
      assert Xq.attr(core, "Extension") == "xml"
    end
  end
end
