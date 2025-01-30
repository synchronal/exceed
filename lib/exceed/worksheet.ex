defmodule Exceed.Worksheet do
  # @related [tests](test/exceed/worksheet_test.exs)

  @moduledoc """
  Worksheets represent the tabular data to be included in an Excel sheet, in
  addition to metadata about the sheet and how it should be rendered.

  ## Examples

  ``` elixir
  iex> headers = ["header 1"]
  iex> rows = [["row 1"], ["row 2"]]
  iex> ws = Exceed.Worksheet.new("Sheet Name", headers, rows)
  #Exceed.Worksheet<name: "Sheet Name", ...>
  iex>
  iex> Exceed.Workbook.new("creator name")
  ...>  |> Exceed.Workbook.add_worksheet(ws)
  #Exceed.Workbook<sheets: ["Sheet Name"]>
  ```

  ## Sheet content

  Rows are represented by an enumerable where each row will be resolved to a
  list of cells. In the above example, a list of lists is provided.
  Alternatively, a stream may be provided.

  ``` elixir
  iex> stream = Stream.repeatedly(fn -> [:rand.uniform(), :rand.uniform()] end)
  ...>
  iex> Exceed.Worksheet.new("Sheet Name", ["Random 1", "Random 2"], stream)
  #Exceed.Worksheet<name: "Sheet Name", ...>
  ```

  Values in each row execute the `Exceed.Worksheet.Cell` protocol to convert
  Elixir data structures to XML using appropriate SpreadsheetML tags and
  determine the appropriate XML attributes to merge onto the cell.

  ## Sheet options

  When initializing a worksheet, default options may be overridded by providing
  an options via the optional fourth argument to `Exceed.Worksheet.new/4`.

  ``` elixir
  iex> headers = ["header 1"]
  iex> rows = [["row 1"], ["row 2"]]
  iex> opts = [cols: [padding: 6.325, widths: %{2 => 10.75}]]
  iex>
  iex> Exceed.Worksheet.new("Sheet Name", headers, rows, opts)
  #Exceed.Worksheet<name: "Sheet Name", ...>
  ```

  - Column padding - `cols: [padding: value]` - default: `4.25` - extra space
    given to each column, in addition to whatever is determined from the
    headers or the specified widths. Not used when an exact width is specified
    for a column.
  - Column width - `cols: [widths: %{1 => 15.75}]` - specify the exact width
    of specific columns as a map of 1-indexed column indexes to floats. When not
    provided, this is automatically determined from the character length of the
    relevant header cell, or from the first row when no headers are provided.

  ### Column widths

  1. Note that the actual rendered width of a cell depends on the character
    width of the applied font, on the computer used to open the spreadsheet (see
    the [OpenXML.Spreadsheet Column docs](https://learn.microsoft.com/en-us/dotnet/api/documentformat.openxml.spreadsheet.column?view=openxml-3.0.1)
    for more info).

  """
  alias Exceed.Worksheet.Cell
  alias XmlStream, as: Xs

  @type headers() :: [String.t()] | nil
  @type spreadsheet_options() :: [spreadsheet_option()]
  @type spreadsheet_option() :: {:cols, [columns_option()]}
  @type columns_option() ::
          {:padding, float()}
          | {:widths, %{integer() => float()}}

  @type t() :: %__MODULE__{
          content: Enum.t(),
          headers: headers(),
          name: String.t(),
          opts: spreadsheet_options()
        }

  @derive {Inspect, only: [:name]}
  defstruct ~w(
    content
    headers
    name
    opts
  )a

  @doc """
  Initialize a new worksheet to be added to a workbook. See `Exceed.Workbook.add_worksheet/2`.
  For worksheet options, see the module docs for `m:Exceed.Worksheet#module-sheet-options`.

  ## Examples

  ``` elixir
  iex> headers = ["header 1"]
  iex> rows = [["row 1"], ["row 2"]]
  iex> opts = [cols: [padding: 6.325]]
  iex> %Worksheet{} = Exceed.Worksheet.new("Sheet Name", headers, rows, opts)

  ```
  """
  @spec new(String.t(), headers(), Enum.t(), keyword()) :: t()
  def new(name, headers, content, opts \\ [])

  def new(_name, [], _content, _opts),
    do: raise(Exceed.Error, "Worksheet headers must be a list of items or nil")

  def new(name, headers, content, opts),
    do: __struct__(name: name, headers: headers, content: content, opts: opts)

  @doc false
  def to_xml(%__MODULE__{headers: headers, content: content, opts: opts}) do
    %{
      col_padding: col_padding,
      col_widths: col_widths
    } = normalize_opts(opts)

    [
      Xs.declaration(version: "1.0", encoding: "UTF-8"),
      Xs.element(
        "worksheet",
        %{
          "xmlns" => Exceed.Namespace.main(),
          "xmlns:r" => Exceed.Namespace.relationships(),
          "xml:space" => "preserve"
        },
        [
          Xs.element("sheetPr", [Xs.empty_element("pageSetUpPr", %{"fitToPage" => "0"})]),
          Xs.element("sheetViews", [
            Xs.empty_element("sheetView", %{
              "defaultGridColor" => "1",
              "rightToLeft" => "0",
              "showFormulas" => "0",
              "showGridLines" => "1",
              "showOutlineSymbols" => "0",
              "showRowColHeaders" => "1",
              "showRuler" => "1",
              "showWhiteSpace" => "0",
              "showZeros" => "1",
              "tabSelected" => "0",
              "windowProtection" => "0",
              "workbookViewId" => "0",
              "zoomScale" => "100",
              "zoomScaleNormal" => "0",
              "zoomScalePageLayoutView" => "0",
              "zoomScaleSheetLayoutView" => "0"
            })
          ]),
          Xs.empty_element("sheetFormatPr", %{"baseColWidth" => "8", "defaultRowHeight" => "18"}),
          cols(headers, content, col_padding, col_widths),
          Xs.element("sheetData", sheet_data(content, headers)),
          Xs.empty_element("sheetCalcPr", %{"fullCalcOnLoad" => "1"}),
          Xs.empty_element("printOptions", %{
            "gridLines" => "0",
            "headings" => "0",
            "horizontalCentered" => "0",
            "verticalCentered" => "0"
          }),
          Xs.empty_element("pageMargins", %{
            "bottom" => "1.0",
            "footer" => "0.5",
            "header" => "0.5",
            "left" => "0.75",
            "right" => "0.75",
            "top" => "1.0"
          }),
          Xs.empty_element("pageSetup"),
          Xs.empty_element("headerFooter")
        ]
      )
    ]
  end

  # # #

  defp cell_idx_to_letter(x), do: IO.chardata_to_string(:lists.reverse(x))

  defp cols(nil, content, padding, widths) do
    case content |> Stream.take(1) |> Enum.to_list() do
      [headers] -> cols(headers, content, padding, widths)
    end
  end

  defp cols(headers, _content, padding, widths) do
    Xs.element(
      "cols",
      for {header, i} <- Enum.with_index(headers, 1) do
        width = Map.get(widths, i, String.length(to_string(header)) + padding)
        Xs.empty_element("col", %{"min" => i, "max" => i, "width" => width})
      end
    )
  end

  defp normalize_opts(opts) do
    %{
      col_padding: get_in(opts, [:cols, :padding]) || 4.25,
      col_widths: get_in(opts, [:cols, :widths]) || %{}
    }
  end

  defp next_alphabet([x | rest]) when x >= ?A and x < ?Z, do: [x + 1 | rest]
  defp next_alphabet([]), do: [?A]
  defp next_alphabet([x | rest]) when x == ?Z, do: [?A | next_alphabet(rest)]

  defp prepend_headers(stream, nil), do: stream
  defp prepend_headers(stream, headers), do: Stream.concat([headers], stream)

  defp sheet_data(stream, headers) do
    stream
    |> prepend_headers(headers)
    |> Stream.transform(1, fn row, row_idx ->
      to_row(row, row_idx)
    end)
  end

  defp to_cells(row, row_idx) do
    Enum.reduce(row, {[], [?A]}, fn cell, {cells, count} ->
      attrs = Cell.to_attrs(cell)
      body = Cell.to_content(cell)
      cell_letter = cell_idx_to_letter(count)

      {:lists.append(cells, Xs.element("c", Map.put(attrs, "r", cell_letter <> row_idx), body)), next_alphabet(count)}
    end)
    |> elem(0)
  end

  defp to_row(items, row_idx) do
    identifier = to_string(row_idx)
    {[Xs.element("row", %{"r" => identifier}, to_cells(items, identifier))], row_idx + 1}
  end
end
