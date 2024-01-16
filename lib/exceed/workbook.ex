defmodule Exceed.Workbook do
  # @related [tests](test/exceed/workbook_test.exs)
  @moduledoc """
  The top-level structure for collecting structures that will be converted to an
  Excel file.

  ## Examples

  ``` elixir
  iex> Exceed.Workbook.new()
  %Exceed.Workbook{sheets: []}
  ```
  """

  defstruct sheets: []

  def new, do: __struct__()
end
