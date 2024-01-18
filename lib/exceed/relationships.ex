defmodule Exceed.Relationships do
  @moduledoc false

  def type(type),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/" <> type
end
