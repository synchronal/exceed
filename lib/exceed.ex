defmodule Exceed do
  # @related [tests](test/exceed_test.exs)
  @moduledoc """
  `Exceed` is a high-level stream-oriented library for generating Excel files.
  """

  def stream!(%Exceed.Workbook{} = _wb) do
    Zstream.zip([
      Exceed.ContentType.to_file(),
      Exceed.Relationships.to_file()
    ])
  end
end
