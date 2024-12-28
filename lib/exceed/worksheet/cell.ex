defprotocol Exceed.Worksheet.Cell do
  # @related [tests](test/exceed/worksheet/cell_test.exs)

  @moduledoc """
  A protocol for transforming source data into data structures that can be streamed
  to appropriate SpreadsheetML tags, using the `XmlStream` library.

  This protocol is implemented for floats, integers, strings, and binaries, in addition
  to `Date`, `DateTime`, and `NaiveDateTime`. If the [decimal](https://hex.pm/packages/decimal)
  library is present, this protocoal is automatically implemented for `Decimal`.

  ## Examples

  ``` elixir
  defimpl Exceed.Worksheet.Cell, for: MyStruct do
    alias XmlStream, as: Xs

    def to_attrs(%MyStruct{value: value}) when is_binary(value),
      do: %{"t" => "inlineStr"}

    def to_content(%MyStruct{value: value}) when is_binary(value),
      do: Xs.element("is", [Xs.element("t", [Xs.content(value)])])
  end
  ```
  """

  @doc """
  For a given data type, these attributes will be merged onto the `c` tag wrapping
  this cell's content. Note that the `r` attribute (designating the cell's identifier
  in `A1` format) will be calculated when streaming a worksheet to XLSX, and should
  _not_ be included in this output.
  """
  @spec to_attrs(t) :: XmlStream.attrs()
  def to_attrs(value)

  @doc """
  For a given data type, convert the value to a list of tags. Functions from
  `XmlStream` including `XmlStream.element/3`, `XmlStream.empty_element/2`, and
  `XmlStream.content/1` may be used to facilitate the generation of tags.
  """
  @spec to_content(t) :: XmlStream.fragment()
  def to_content(value)
end

defimpl Exceed.Worksheet.Cell, for: Atom do
  alias XmlStream, as: Xs

  def to_attrs(v) when is_boolean(v), do: %{"t" => "b"}
  def to_attrs(_), do: %{"t" => "inlineStr"}

  def to_content(true), do: Xs.element("v", [Xs.content("1")])
  def to_content(false), do: Xs.element("v", [Xs.content("0")])

  def to_content(value),
    do: Xs.element("is", [Xs.element("t", [Xs.content("#{value}")])])
end

defimpl Exceed.Worksheet.Cell, for: Float do
  alias XmlStream, as: Xs

  def to_attrs(_), do: %{"t" => "n"}

  def to_content(value),
    do: Xs.element("v", [Xs.content(to_string(value))])
end

defimpl Exceed.Worksheet.Cell, for: Integer do
  alias XmlStream, as: Xs

  def to_attrs(_), do: %{"t" => "n"}

  def to_content(value),
    do: Xs.element("v", [Xs.content(to_string(value))])
end

defimpl Exceed.Worksheet.Cell, for: String do
  alias XmlStream, as: Xs

  def to_attrs(_), do: %{"t" => "inlineStr"}

  def to_content(value),
    do: Xs.element("is", [Xs.element("t", [Xs.content(value)])])
end

defimpl Exceed.Worksheet.Cell, for: BitString do
  alias XmlStream, as: Xs

  def to_attrs(_), do: %{"t" => "inlineStr"}

  def to_content(value),
    do: Xs.element("is", [Xs.element("t", [Xs.content(value)])])
end

defimpl Exceed.Worksheet.Cell, for: Date do
  import Exceed.Util.Guards, only: [is_valid_year?: 1]
  alias Exceed.Util

  def to_attrs(%Date{year: year}) when is_valid_year?(year), do: %{"s" => "1"}
  def to_attrs(%Date{}), do: %{"t" => "inlineStr"}

  def to_content(value),
    do: Util.to_excel_datetime(value) |> Exceed.Worksheet.Cell.to_content()
end

defimpl Exceed.Worksheet.Cell, for: DateTime do
  import Exceed.Util.Guards, only: [is_valid_year?: 1]
  alias Exceed.Util

  def to_attrs(%DateTime{year: year}) when is_valid_year?(year), do: %{"s" => "2"}
  def to_attrs(%DateTime{}), do: %{"t" => "inlineStr"}

  def to_content(value),
    do: Util.to_excel_datetime(value) |> Exceed.Worksheet.Cell.to_content()
end

defimpl Exceed.Worksheet.Cell, for: NaiveDateTime do
  import Exceed.Util.Guards, only: [is_valid_year?: 1]
  alias Exceed.Util

  def to_attrs(%NaiveDateTime{year: year}) when is_valid_year?(year), do: %{"s" => "2"}
  def to_attrs(%NaiveDateTime{}), do: %{"t" => "inlineStr"}

  def to_content(value),
    do: Util.to_excel_datetime(value) |> Exceed.Worksheet.Cell.to_content()
end

if Code.ensure_loaded?(Decimal) do
  defimpl Exceed.Worksheet.Cell, for: Decimal do
    alias XmlStream, as: Xs

    def to_attrs(_), do: %{"t" => "n"}

    def to_content(value),
      do: Xs.element("v", [Xs.content(to_string(value))])
  end
end
