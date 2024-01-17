defmodule Exceed do
  # @related [tests](test/exceed_test.exs)
  @moduledoc """
  `Exceed` is a high-level stream-oriented library for generating Excel files.
  """

  def stream!(%Exceed.Workbook{} = wb) do
    Zstream.zip([
      Exceed.ContentType.to_file(),
      Exceed.Relationships.Default.to_file(),
      Exceed.DocProps.App.to_file(),
      Exceed.DocProps.Core.to_file(wb.creator),
      Exceed.Relationships.Workbook.to_file()
    ])
  end
end
