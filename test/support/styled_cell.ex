defmodule Exceed.Test.StyledCell do
  @moduledoc false
  defstruct [:value, style: :bold]
end

defimpl Exceed.Worksheet.Cell, for: Exceed.Test.StyledCell do
  def to_attrs(%{style: style}), do: %{"t" => "n", "s" => style}
  def to_content(%{value: value}), do: Exceed.Worksheet.Cell.to_content(value)
end
