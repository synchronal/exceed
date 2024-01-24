defmodule Exceed.Workbook do
  # @related [tests](test/exceed/workbook_test.exs)

  @moduledoc """
  The top-level data structure that collects worksheets and metadata for
  generating an Excel file.

  ## Examples

  ``` elixir
  iex> Exceed.Workbook.new("creator name")
  #Exceed.Workbook<sheets: []>
  ```

  ``` elixir
  iex> headers = ["header 1"]
  iex> rows = Stream.repeatedly(fn -> [:rand.uniform(), :rand.uniform()] end)
  iex> ws = Exceed.Worksheet.new("Sheet Name", headers, rows)
  ...>
  iex> Exceed.Workbook.new("creator name")
  ...>   |> Exceed.Workbook.add_worksheet(ws)
  #Exceed.Workbook<sheets: ["Sheet Name"]>
  ```
  """

  alias Exceed.Worksheet
  alias XmlStream, as: Xs

  @type t() :: %__MODULE__{
          creator: String.t(),
          worksheets: [Worksheet.t()]
        }

  defstruct [
    :creator,
    worksheets: []
  ]

  @doc """
  Initialize a new workbook with a creator name.
  """
  @spec new(String.t()) :: t()
  def new(creator), do: __struct__(creator: creator)

  @doc """
  Adds an `Exceed.Worksheet` to the workbook.
  """
  @spec add_worksheet(t(), Exceed.Worksheet.t()) :: t()
  def add_worksheet(%__MODULE__{} = wb, %Worksheet{} = ws),
    do: %{wb | worksheets: [ws | wb.worksheets]}

  @doc false
  def finalize(%__MODULE__{worksheets: worksheets} = wb),
    do: %{wb | worksheets: Enum.reverse(worksheets)}

  @doc false
  def to_xml(%__MODULE__{worksheets: worksheets}) do
    [
      Xs.declaration(version: "1.0", encoding: "UTF-8"),
      Xs.element(
        "workbook",
        %{"xmlns" => Exceed.Namespace.main(), "xmlns:r" => Exceed.Namespace.doc_relationships()},
        [
          Xs.element(
            "sheets",
            for {ws, i} <- Enum.with_index(worksheets, 1) do
              rel_idx = Exceed.Relationships.Workbook.sheet_index(i)
              Xs.empty_element("sheet", %{"name" => ws.name, "sheetId" => "#{i}", "r:id" => "rId#{rel_idx}"})
            end
          )
        ]
      )
    ]
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(wb, opts) do
      worksheet_names = Enum.map(wb.worksheets, & &1.name)
      concat(["#Exceed.Workbook<sheets: ", Inspect.List.inspect(worksheet_names, opts), ">"])
    end
  end
end
