defmodule Exceed.ApiContractTest do
  use ExUnit.Case, async: true
  alias Exceed.Test.StyledCell

  test "keeps protocol styling when assigning a number format" do
    files =
      Exceed.Workbook.new("Contract")
      |> Exceed.Workbook.add_worksheet(
        Exceed.Worksheet.new(
          "Report",
          ["Amount", "Override", "Protocol"],
          [[%StyledCell{value: 12}, %StyledCell{value: 34}, %StyledCell{value: 56}]],
          cells: [{"A*", format: :amount}, {"B*", format: "0.00"}, {"B2", style: :center}],
          formats: [amount: "0.00"],
          styles: [bold: [bold: true], center: [align: :center]]
        )
      )
      |> Exceed.stream!()
      |> extract()

    assert format(files, "A2") == "0.00"
    assert style_attr(files, "A2", "@fontId") == "1"
    assert xpath(files["xl/worksheets/sheet1.xml"], "//c[@r='A2']/v") == "12"
    assert format(files, "B2") == "0.00"
    assert style_attr(files, "B2", "alignment/@horizontal") == "center"
    assert style_attr(files, "B2", "@fontId") == "0"
    assert style_attr(files, "C2", "@fontId") == "1"

    for {date_style, bold_style} <- [{1, 4}, {"1", "4"}] do
      files =
        Exceed.Workbook.new("Contract")
        |> Exceed.Workbook.add_worksheet(
          Exceed.Worksheet.new(
            "Report",
            ["Date", "Amount"],
            [[%StyledCell{value: 46340, style: date_style}, %StyledCell{value: 12, style: bold_style}]],
            cells: [{"A*", style: :bold}, {"B*", format: :amount}],
            formats: [amount: "0.00"],
            styles: [bold: [bold: true]]
          )
        )
        |> Exceed.stream!()
        |> extract()

      assert format(files, "A2") == "yyyy-mm-dd"
      assert format(files, "B2") == "0.00"
      for ref <- ["A2", "B2"], do: assert(style_attr(files, ref, "@fontId") == "1")
    end
  end

  test "keeps formats and styles local to each worksheet" do
    workbook =
      Enum.reduce(
        [{"0.00", "dd.mm.yyyy", [bold: true]}, {"0.000", "yyyy/mm/dd", [align: :right]}],
        Exceed.Workbook.new("Contract"),
        fn {amount, date, style}, workbook ->
          worksheet =
            Exceed.Worksheet.new(
              amount,
              ["Amount", "Date", "Common"],
              [[12, ~D[2026-11-14], 34], [nil, ~D[2026-11-14], nil]],
              formats: [amount: amount, date: date],
              styles: [total: style],
              cells: [{"A*", format: :amount}, {"*2", style: :total}, {"B2", format: :date, style: :total}]
            )

          Exceed.Workbook.add_worksheet(workbook, worksheet)
        end
      )

    files = workbook |> Exceed.stream!() |> extract()

    for {sheet, amount, date, font, alignment} <- [
          {1, "0.00", "dd.mm.yyyy", "1", ""},
          {2, "0.000", "yyyy/mm/dd", "0", "right"}
        ] do
      sheet_files = Map.put(files, "xl/worksheets/sheet1.xml", files["xl/worksheets/sheet#{sheet}.xml"])
      assert format(sheet_files, "A2") == amount
      assert format(sheet_files, "B2") == date
      assert format(sheet_files, "B3") == date

      for ref <- ["A2", "B2", "C2"] do
        assert style_attr(sheet_files, ref, "@fontId") == font
        assert style_attr(sheet_files, ref, "alignment/@horizontal") == alignment
      end
    end
  end

  test "accepts column numbers and letters" do
    for {format_column, style_column, ref, width} <- [
          {2, "B", "B2", 2},
          {"B", 2, "B2", 2},
          {27, "AA", "AA2", 27},
          {"AA", 27, "AA2", 27}
        ] do
      files =
        Exceed.Workbook.new("Contract")
        |> Exceed.Workbook.add_worksheet(
          Exceed.Worksheet.new("Report", List.duplicate("Amount", width), [List.duplicate(12, width)],
            cells: [{{:column, format_column}, format: "0.00"}, {{:column, style_column}, style: :total}],
            styles: [total: [bold: true]]
          )
        )
        |> Exceed.stream!()
        |> extract()

      assert format(files, ref) == "0.00"
      assert style_attr(files, ref, "@fontId") == "1"
    end
  end

  test "applies cells before rows before columns independently" do
    files =
      Exceed.Workbook.new("Contract")
      |> Exceed.Workbook.add_worksheet(
        Exceed.Worksheet.new("Report", ["A", "B", "C", "D"], [[12, 34, 56, 78], [12, 34, 56, 78]],
          formats: [amount: "0.00"],
          styles: [column: [bold: true], row: [align: :center]],
          cols: [
            {1, width: 24.0, format: :amount, style: :column},
            {"B", width: 18.0, format: "0.00", style: [bold: true]}
          ],
          rows: [{1, height: 30.0, style: :row}, {2, format: "0.000", style: :row}],
          cells: [
            {"A2", style: [align: :right]},
            {"C2", format: "0.0000"},
            {"D2", format: "0.00", style: [bold: true]},
            {"D2", format: "0.00000"}
          ]
        )
      )
      |> Exceed.stream!()
      |> extract()

    for {ref, code, font, align} <- [
          {"A2", "0.000", "0", "right"},
          {"B2", "0.000", "0", "center"},
          {"C2", "0.0000", "0", "center"},
          {"D2", "0.00000", "1", ""},
          {"A3", "0.00", "1", ""},
          {"B3", "0.00", "1", ""},
          {"A1", "0.00", "0", "center"}
        ] do
      assert format(files, ref) == code
      assert style_attr(files, ref, "@fontId") == font
      assert style_attr(files, ref, "alignment/@horizontal") == align
    end

    sheet = files["xl/worksheets/sheet1.xml"]
    assert xpath(sheet, "//col[@min='1']/@width") == "24.0"
    assert xpath(sheet, "//col[@min='2']/@width") == "18.0"
    assert xpath(sheet, "//row[@r='1']/@ht") == "30.0"
    assert xpath(sheet, "//row[@r='1']/@customHeight") == "1"
  end

  test "rejects number formats in styles and unknown assignments" do
    invalid_names =
      for name <- [nil, false], {key, value} <- [styles: [], formats: "0.00"], do: [{key, [{name, value}]}]

    for opts <-
          invalid_names ++
            [
              [styles: [bad: [num_format: "0.00"]]],
              [cells: [{"A*", style: :missing}]],
              [cells: [{"A*", format: :missing}]],
              [cells: [{"A*", style: nil}]],
              [cells: [{"A*", format: false}]],
              [cells: [{"A*", style: [num_format: "0.00"]}]],
              [cells: [{"A*", style: [bold: "true"]}]],
              [cells: [{{:column, 0}, format: :amount}]],
              [cells: [{{:column, "a"}, style: :header}]],
              [cells: [{"A0", format: :amount}]],
              [rows: [{0, height: 20.0}]],
              [cols: [{"a", width: 20.0}]]
            ] do
      assert_raise ArgumentError, fn ->
        Exceed.Workbook.new("Contract")
        |> Exceed.Workbook.add_worksheet(Exceed.Worksheet.new("Report", ["Amount"], [], opts))
        |> Exceed.stream!()
      end
    end
  end

  test "preserves Excel dates, local datetimes and per-value offsets" do
    local = ~U[2026-11-14 12:00:00Z]

    rows =
      for offset <- [10_800, -18_000], do: [~D[2026-11-14], %{local | utc_offset: offset}, DateTime.to_naive(local)]

    files =
      Exceed.Workbook.new("Dates")
      |> Exceed.Workbook.add_worksheet(
        Exceed.Worksheet.new("Sheet", ["Date", "Zoned", "Naive"], rows,
          formats: [datetime: "yyyy-mm-dd hh:mm:ss {offset}"],
          rows: [{2, style: [bold: true]}]
        )
      )
      |> Exceed.stream!()
      |> extract()

    for {ref, code, value} <- [
          {"A2", "yyyy-mm-dd", "46340.0"},
          {"B2", ~s(yyyy-mm-dd hh:mm:ss "+0300"), "46340.5"},
          {"B3", ~s(yyyy-mm-dd hh:mm:ss "-0500"), "46340.5"},
          {"C2", "yyyy-mm-dd hh:mm:ss", "46340.5"}
        ] do
      assert format(files, ref) == code
      assert xpath(files["xl/worksheets/sheet1.xml"], "//c[@r='#{ref}']/v") == value
    end

    for ref <- ["A2", "B2", "C2"], do: assert(style_attr(files, ref, "@fontId") == "1")
  end

  test "streams rows once, yields before exhaustion and closes the source on halt" do
    for headers <- [["Number", "Text"], nil] do
      Process.put(:rows_seen, 0)
      Process.put(:source_closed, false)

      rows =
        Stream.resource(
          fn -> 1 end,
          fn index ->
            assert index == Process.get(:rows_seen) + 1
            if index > 5000, do: raise("source exhausted before worksheet bytes were delivered")
            Process.put(:rows_seen, index)
            {[[index, Float.to_string(:rand.uniform())]], index + 1}
          end,
          fn _ -> Process.put(:source_closed, true) end
        )

      stream =
        Exceed.Workbook.new("Streaming")
        |> Exceed.Workbook.add_worksheet(Exceed.Worksheet.new("Sheet", headers, rows))
        |> Exceed.stream!()

      assert Process.get(:rows_seen) == 0
      Enum.find(stream, fn _chunk -> Process.get(:rows_seen) > 0 end)
      assert Process.get(:rows_seen) in 1..4999
      assert Process.get(:source_closed)
    end
  end

  test "reads a headerless source once and uses its first row for column widths" do
    Process.put(:rows_seen, 0)

    rows =
      Stream.map([["First", 12], ["Second", 34]], fn row ->
        Process.put(:rows_seen, Process.get(:rows_seen) + 1)
        row
      end)

    stream =
      Exceed.Workbook.new("Headerless")
      |> Exceed.Workbook.add_worksheet(
        Exceed.Worksheet.new("Sheet", nil, rows, cols: [{2, width: 18.0, format: "0.00"}])
      )
      |> Exceed.stream!()

    assert Process.get(:rows_seen) == 0
    files = extract(stream)
    sheet = files["xl/worksheets/sheet1.xml"]
    assert Process.get(:rows_seen) == 2
    assert xpath(sheet, "count(//row)") == "2"
    assert xpath(sheet, "//c[@r='A1']/is/t") == "First"
    assert xpath(sheet, "//c[@r='B2']/v") == "34"
    assert xpath(sheet, "//col[@min='1']/@width") == "9.25"
    assert xpath(sheet, "//col[@min='2']/@width") == "18.0"
    assert format(files, "B1") == "0.00"
  end

  test "writes an empty headerless stream" do
    files =
      Exceed.Workbook.new("Empty")
      |> Exceed.Workbook.add_worksheet(Exceed.Worksheet.new("Sheet", nil, Stream.map([], & &1)))
      |> Exceed.stream!()
      |> extract()

    sheet = files["xl/worksheets/sheet1.xml"]
    assert xpath(sheet, "count(/worksheet/sheetData)") == "1"
    assert xpath(sheet, "count(//row | //col)") == "0"
  end

  defp extract(stream) do
    {:ok, entries} = stream |> Enum.to_list() |> IO.iodata_to_binary() |> :zip.extract([:memory])

    Map.new(entries, fn {name, xml} ->
      {document, _} = :xmerl_scan.string(:binary.bin_to_list(xml))
      {List.to_string(name), document}
    end)
  end

  defp style_attr(files, ref, path) do
    index = xpath(files["xl/worksheets/sheet1.xml"], "//c[@r='#{ref}']/@s") |> String.to_integer()
    xpath(files["xl/styles.xml"], "//cellXfs/xf[#{index + 1}]/#{path}")
  end

  defp format(files, ref) do
    id = style_attr(files, ref, "@numFmtId")
    xpath(files["xl/styles.xml"], "//numFmt[@numFmtId='#{id}']/@formatCode")
  end

  defp xpath(document, path) do
    {:xmlObj, :string, value} = :xmerl_xpath.string(String.to_charlist("string(#{path})"), document)
    :unicode.characters_to_binary(value)
  end
end
