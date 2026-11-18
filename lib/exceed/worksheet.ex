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
  - Columns - `cols: [{2, width: 24.0, format: :amount, style: :total}]` -
    column settings, addressed by 1-based number or uppercase letters.
  - Rows - `rows: [{1, height: 30.0, style: :header}]` - row settings,
    addressed by 1-based number. Heights are in points.
  - Cells - `cells: [{"B7", format: :amount, style: :total}]` -
    assign formats and appearance independently. Formats accept a declared name or
    a direct Excel format string, e.g. `{"B7", format: "0.00", style: :total}`.
    Styles also accept options directly, e.g. `{"*1", style: [bold: true, align: :center]}`.
    Columns also accept a 1-based number or letters: `{{:column, 2}, format: :amount}`
    and `{{:column, "B"}, style: :header}` both target column B.
    Patterns use uppercase column letters and 1-based row numbers, including headers.
    Cells take precedence over rows, which take precedence over columns. Within each level,
    the last rule wins separately for each property. Rules do not change value types.
  - Formats - `formats: [amount: "0.00", datetime: "yyyy-mm-dd hh:mm:ss {offset}"]` -
    declare number formats for this sheet. `:date` and `:datetime` override the built-in formats.
  - Styles - `styles: [header: [bold: true, align: :center]]` - declare named appearance
    options for this sheet: `:bold`, `:bg_color`, `:border`, `:align`, `:valign`, `:wrap_text`.
    Number formats belong in `:formats` or a cell rule's `:format`, never inside a style.

  ### Column widths

  1. Note that the actual rendered width of a cell depends on the character
    width of the applied font, on the computer used to open the spreadsheet (see
    the [OpenXML.Spreadsheet Column docs](https://learn.microsoft.com/en-us/dotnet/api/documentformat.openxml.spreadsheet.column?view=openxml-3.0.1)
    for more info).

  """
  @type headers() :: [String.t()] | nil
  @type spreadsheet_options() :: [spreadsheet_option()]
  @type spreadsheet_option() ::
          {:cols, [columns_option() | {pos_integer() | String.t(), keyword()}]}
          | {:rows, [{pos_integer(), keyword()}]}
          | {:cells, [{cell_selector(), keyword()}]}
          | {:formats, keyword(String.t())}
          | {:styles, keyword(keyword())}
  @type cell_selector() :: String.t() | {:column, pos_integer() | String.t()}
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

  @doc false
  def prepare(%__MODULE__{opts: opts}) do
    config = Exceed.Stylesheet.config(Keyword.get(opts, :styles, []), Keyword.get(opts, :formats, []))
    normalize_opts(opts, config)
  end

  @doc false
  def column_name(number) when number <= 26, do: <<?A + number - 1>>
  def column_name(number), do: column_name(div(number - 1, 26)) <> <<?A + rem(number - 1, 26)>>

  # # #

  defp normalize_opts(opts, config \\ %{formats: %{}, styles: %{}, cell_xfs: %{}}) do
    {defaults, columns} = Enum.split_with(Keyword.get(opts, :cols, []), fn {key, _} -> key in [:padding, :widths] end)

    columns =
      for {column, settings} <- columns do
        {column_index(column), Keyword.validate!(settings, [:width, :format, :style])}
      end

    rows =
      for {row, settings} <- Keyword.get(opts, :rows, []) do
        unless is_integer(row) and row > 0, do: raise(ArgumentError, "invalid row: #{inspect(row)}")
        {row, Keyword.validate!(settings, [:height, :format, :style])}
      end

    cells =
      Enum.map(columns, fn {column, settings} -> {{:column, column}, Keyword.take(settings, [:format, :style])} end) ++
        Enum.map(rows, fn {row, settings} -> {"*#{row}", Keyword.take(settings, [:format, :style])} end) ++
        Keyword.get(opts, :cells, [])

    rules = compile_cell_rules(cells, %{format: config.formats, style: config.styles})

    %{
      col_padding: Keyword.get(defaults, :padding, 4.25),
      col_widths:
        Map.merge(
          Keyword.get(defaults, :widths, %{}),
          Map.new(for {column, settings} <- columns, {:width, width} <- settings, do: {column, width})
        ),
      row_heights:
        Map.new(for {row, settings} <- rows, {:height, height} <- settings, do: {Integer.to_string(row), height}),
      style_config: config,
      style_registry: Keyword.get(opts, :style_registry),
      date_style: Keyword.get(opts, :date_style, 1),
      cell_formats: rules.format,
      cell_styles: rules.style
    }
  end

  defp compile_cell_rules(cells, definitions) do
    # Index once instead of scanning every rule for every cell.
    for {pattern, settings} <- cells,
        settings = Keyword.validate!(settings, [:format, :style]),
        settings != [],
        reduce: %{format: %{}, style: %{}} do
      acc ->
        selector =
          case Regex.run(~r/\A([A-Z]+|\*)([1-9][0-9]*|\*)\z/, cell_pattern(pattern), capture: :all_but_first) do
            [column, row] when column != "*" or row != "*" ->
              case {column, row} do
                {"*", row} -> row
                {column, "*"} -> column
                cell -> cell
              end

            _ ->
              raise ArgumentError, "invalid cell style pattern: #{inspect(pattern)}"
          end

        for {key, name} <- settings, reduce: acc do
          acc ->
            name = if key == :style and is_list(name), do: Exceed.Stylesheet.style_options(name), else: name
            direct = (key == :format and is_binary(name)) or (key == :style and is_list(name))

            unless name not in [nil, false] and (Map.has_key?(definitions[key], name) or direct),
              do: raise(ArgumentError, "unknown cell #{key}: #{inspect(name)}")

            value = if key == :style, do: Map.get(definitions[key], name, name), else: name
            Map.update!(acc, key, &Map.put(&1, selector, value))
        end
    end
  end

  defp column_index(number) when is_integer(number) and number > 0, do: number

  defp column_index(letters) when is_binary(letters) do
    unless Regex.match?(~r/\A[A-Z]+\z/, letters), do: raise(ArgumentError, "invalid column: #{inspect(letters)}")

    for <<letter <- letters>>, reduce: 0 do
      number -> number * 26 + letter - ?A + 1
    end
  end

  defp column_index(column), do: raise(ArgumentError, "invalid column: #{inspect(column)}")

  defp cell_pattern({:column, number}) when is_integer(number) and number > 0,
    do: column_name(number) <> "*"

  defp cell_pattern({:column, letters}) when is_binary(letters), do: letters <> "*"
  defp cell_pattern(pattern) when is_binary(pattern), do: pattern
  defp cell_pattern(pattern), do: raise(ArgumentError, "invalid cell style pattern: #{inspect(pattern)}")
end
