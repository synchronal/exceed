defmodule Benchmark do
  def run(opts \\ [], column_count \\ 10, row_count \\ 100_000) do
    headers = headers(column_count)
    stream = stream(column_count, row_count)

    benchmark(column_count, row_count, fn ->
      Exceed.Worksheet.new("Sheet Name", headers, stream)
      |> Exceed.Worksheet.to_xml()
      |> Exceed.File.file("xl/worksheets/sheet1.xml", opts)
      |> List.wrap()
      |> Zstream.zip()
      |> Stream.run()
    end)
  end

  defp headers(column_count) do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.map(&"Header #{&1}")
    |> Enum.take(column_count)
  end

  defp benchmark(column_count, batch_size, fun) do
    {duration, _} = :timer.tc(fun, :millisecond)

    rate_per_row = Float.round(batch_size / (duration / 1_000), 2)
    IO.puts("Batch size #{column_count}*#{batch_size} completed in #{duration}ms, rate: #{rate_per_row} rows/sec")
  end

  def stream(column_count, row_count) do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.chunk_every(column_count)
    |> Stream.take(row_count)
  end
end
