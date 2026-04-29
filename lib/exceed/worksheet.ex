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
  def to_xml(%__MODULE__{opts: opts} = worksheet),
    do: Exceed.Worksheet.XmlStream.stream(worksheet, normalize_opts(opts))

  # # #

  defp normalize_opts(opts) do
    %{
      col_padding: get_in(opts, [:cols, :padding]) || 4.25,
      col_widths: get_in(opts, [:cols, :widths]) || %{}
    }
  end
end
