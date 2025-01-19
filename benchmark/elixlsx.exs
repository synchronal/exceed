defmodule Benchmark do
  require Logger

  def run(_opts \\ [], column_count \\ 10, row_count \\ 100_000) do
    headers = headers(column_count)
    rows = stream(column_count, row_count)

    benchmark(column_count, row_count, fn ->
      sheet = %Elixir.Elixlsx.Sheet{name: "Sheet 1", rows: [headers | Enum.to_list(rows)]}
      workbook = %Elixir.Elixlsx.Workbook{sheets: [sheet]}
      workbook |> Elixir.Elixlsx.write_to("/tmp/hello.xlsx")
    end)
  end

  defp benchmark(column_count, batch_size, fun) do
    {duration, _} = :timer.tc(fun, :millisecond)

    rate_per_row = Float.round(batch_size / (duration / 1_000), 2)
    IO.puts("Batch size #{column_count}*#{batch_size} completed in #{duration}ms, rate: #{rate_per_row} rows/sec")
  end

  defp headers(column_count) do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.map(&"Header #{&1}")
    |> Enum.take(column_count)
  end

  def stream(column_count, row_count) do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.chunk_every(column_count)
    |> Stream.take(row_count)
  end
end
