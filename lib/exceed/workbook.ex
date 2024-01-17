defmodule Exceed.Workbook do
  # @related [tests](test/exceed/workbook_test.exs)
  @moduledoc """
  The top-level structure for collecting structures that will be converted to an
  Excel file.

  ## Examples

  ``` elixir
  iex> Exceed.Workbook.new("creator name")
  %Exceed.Workbook{creator: "creator name", sheets: []}
  ```
  """

  defstruct [
    :creator,
    sheets: []
  ]

  def new(creator), do: __struct__(creator: creator)
end
