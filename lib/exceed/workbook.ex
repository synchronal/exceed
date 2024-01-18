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

  @doc false
  def to_xml(%__MODULE__{}) do
    [
      XmlStream.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      XmlStream.element(
        "workbook",
        %{"xmlns" => Exceed.Namespace.main(), "xmlns:r" => Exceed.Namespace.relationships()},
        [
          XmlStream.element("sheets", [])
        ]
      )
    ]
  end
end
