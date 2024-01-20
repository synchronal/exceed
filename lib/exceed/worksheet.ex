defmodule Exceed.Worksheet do
  # @related [tests](test/exceed/worksheet_test.exs)

  @moduledoc """
  Worksheets represent the tabular data to be included in an Excel sheet, in
  addition to metadata about the sheet and how it should be rendered.

  ## Examples

  ``` elixir
  iex> headers = ["header 1"]
  iex> rows = [["row 1"], ["row 2"]]
  iex> %Worksheet{} = ws = Exceed.Worksheet.new("Sheet Name", headers, rows)
  ...>
  iex> Exceed.Workbook.new("creator name")
  ...>  |> Exceed.Workbook.add_worksheet(ws)
  ```

  ## Sheet content

  Rows are represented by an enumerable where each row will be resolved to a
  list of cells. In the above example, a list of lists is provided.
  Alternatively, a stream may be provided.

  ``` elixir
  iex> stream = Stream.repeatedly(fn -> [:rand.uniform(), :rand.uniform()] end)
  ...>
  iex> %Worksheet{} =
  ...>     Exceed.Worksheet.new("Sheet Name", ["Random 1", "Random 2"], stream)
  ```

  ## Options

  When initializing a worksheet, default options may be overridded by providing
  an options via the optional fourth argument to `Exceed.Worksheet.new/4`.

  ``` elixir
  iex> headers = ["header 1"]
  iex> rows = [["row 1"], ["row 2"]]
  iex> opts = [cols: [padding: 6.325]]
  iex> %Worksheet{} = Exceed.Worksheet.new("Sheet Name", headers, rows, opts)
  ```

  - Column padding - `cols: [padding: value]` - default: `4.25` - extra space
    given to each column, in addition to whatever is determined from the
    headers or the specified widths.

  """
  alias XmlStream, as: Xs

  @type headers() :: [String.t()] | nil
  @type spreadsheet_options() :: [spreadsheet_option()]
  @type spreadsheet_option() :: {:cols, [columns_option()]}
  @type columns_option() :: {:padding, float()}

  @type t() :: %__MODULE__{
          content: Enum.t(),
          headers: headers(),
          name: String.t(),
          opts: spreadsheet_options()
        }

  defstruct ~w(
    content
    headers
    name
    opts
  )a

  @doc """
  Initialize a new worksheet to be added to a workbook. See `Exceed.Workbook.add_worksheet/2`.

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
      col_padding: col_padding
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
          cols(headers, content, col_padding),
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

  defp cols(nil, content, padding) do
    case content |> Stream.take(1) |> Enum.to_list() do
      [headers] -> cols(headers, content, padding)
    end
  end

  defp cols(headers, _content, padding) do
    Xs.element(
      "cols",
      for {header, i} <- Enum.with_index(headers, 1) do
        width = String.length(to_string(header)) + padding
        Xs.empty_element("col", %{"min" => i, "max" => i, "width" => width})
      end
    )
  end

  defp normalize_opts(opts) do
    %{
      col_padding: get_in(opts, [:cols, :padding]) || 4.25
    }
  end

  defp sheet_data(stream, headers) do
    stream
    |> prepend_headers(headers)
    |> Stream.transform(1, fn row, row_idx ->
      row(
        row,
        fn
          item when is_number(item) ->
            {%{"t" => "n"}, Xs.element("v", [Xs.content(to_string(item))])}

          item when is_binary(item) ->
            {%{"t" => "inlineStr"}, Xs.element("is", [Xs.element("t", [Xs.content(item)])])}
        end,
        row_idx
      )
    end)
  end

  defp row(items, mapper, row_index) do
    identifier = to_string(row_index)
    {[Xs.element("row", %{"r" => identifier}, cells(items, identifier, mapper))], row_index + 1}
  end

  defp cells(row, row_idx, mapper) do
    Enum.map_reduce(row, [65], fn cell, count ->
      {attrs, body} = mapper.(cell)
      cell_letter = cell_idx_to_letter(count)

      {Xs.element("c", Map.merge(attrs, %{"r" => cell_letter <> row_idx}), body), next_alphabet(count)}
    end)
    |> elem(0)
  end

  defp next_alphabet([x | rest]) when x >= 65 and x < 90, do: [x + 1 | rest]
  defp next_alphabet([]), do: [65]
  defp next_alphabet([x | rest]) when x == 90, do: [65 | next_alphabet(rest)]

  defp cell_idx_to_letter(x), do: IO.chardata_to_string(Enum.reverse(x))

  defp prepend_headers(stream, nil), do: stream
  defp prepend_headers(stream, headers), do: Stream.concat([headers], stream)
end
