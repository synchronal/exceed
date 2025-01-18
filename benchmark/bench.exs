defmodule Benchmark do
  require Logger

  def buffered(column_count \\ 10, row_count \\ 100_000) do
    file = File.stream!("/tmp/workbook.xlsx")
    headers = headers(column_count)
    stream = stream(column_count, row_count)

    benchmark(column_count, row_count, fn ->
      Exceed.Workbook.new("Creator Name")
      |> Exceed.Workbook.add_worksheet(Exceed.Worksheet.new("Sheet Name", headers, stream))
      |> Exceed.stream!()
      |> Stream.into(file)
      |> Stream.run()
    end)
  end

  def unbuffered(column_count \\ 10, row_count \\ 100_000) do
    file = File.stream!("/tmp/workbook.xlsx")
    headers = headers(column_count)
    stream = stream(column_count, row_count)

    benchmark(column_count, row_count, fn ->
      Exceed.Workbook.new("Creator Name")
      |> Exceed.Workbook.add_worksheet(Exceed.Worksheet.new("Sheet Name", headers, stream))
      |> Exceed.stream!(buffer: false)
      |> Stream.into(file)
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
    Logger.info("Batch size #{column_count}*#{batch_size} completed in #{duration}ms, rate: #{rate_per_row} rows/sec")
  end

  def stream(column_count, row_count) do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.chunk_every(column_count)
    |> Stream.take(row_count)
  end
end
