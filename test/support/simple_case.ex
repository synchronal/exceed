defmodule Test.SimpleCase do
  @moduledoc """
  The simplest test case template.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Moar.Assertions
      import Moar.Sugar
      import Test.SimpleCase
    end
  end

  setup [
    :setup_worksheets,
    :setup_workbook
  ]

  def stream_to_file(workbook, tmpdir) do
    filename = Path.join(tmpdir, "workbook.xlsx")

    workbook
    |> Exceed.stream!()
    |> Stream.into(File.stream!(filename))
    |> Stream.run()

    String.to_charlist(filename)
  end

  def extract_file(filename, part) do
    {:ok, handle} = :zip.zip_open(filename, [:memory])
    {:ok, {_zip_name, xml}} = :zip.zip_get(~c"#{part}", handle)
    {:ok, xml}
  end

  def stream_to_xml(wb),
    do:
      wb
      |> XmlStream.stream!()
      |> Enum.to_list()
      |> IO.iodata_to_binary()

  def setup_workbook(%{worksheets: worksheets} = ctx) do
    case Map.get(ctx, :workbook) do
      nil ->
        :ok

      true ->
        wb =
          worksheets
          |> Enum.reduce(Exceed.Workbook.new("me"), &Exceed.Workbook.add_worksheet(&2, &1))
          |> Exceed.Workbook.finalize()

        [wb: wb]
    end
  end

  def setup_worksheets(ctx) do
    worksheets =
      for name <- List.wrap(Map.get(ctx, :sheet, [])) do
        Exceed.Worksheet.new(name, ["Header 1", "Header 2"], [["Value 1", "Value 2"], ["Value 3", "Value 4"]])
      end

    [worksheets: worksheets]
  end
end
