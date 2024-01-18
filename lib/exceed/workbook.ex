defmodule Exceed.Workbook do
  # @related [tests](test/exceed/workbook_test.exs)
  @moduledoc """
  The top-level structure for collecting structures that will be converted to an
  Excel file.

  ## Examples

  ``` elixir
  iex> Exceed.Workbook.new("creator name")
  %Exceed.Workbook{creator: "creator name", worksheets: []}
  ```
  """

  alias Exceed.Worksheet

  @type t() :: %__MODULE__{
          creator: String.t(),
          worksheets: [Worksheet.t()]
        }

  defstruct [
    :creator,
    worksheets: []
  ]

  def new(creator), do: __struct__(creator: creator)

  def add_worksheet(%__MODULE__{} = wb, %Worksheet{} = ws),
    do: %{wb | worksheets: [ws | wb.worksheets]}

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
