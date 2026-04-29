defmodule Benchmark do
  def run(opts \\ [], column_count \\ 10, row_count \\ 100_000) do
    headers = headers(column_count)
    integers = integer_stream(column_count, row_count)
    binaries = binary_stream(column_count, row_count)

    IO.puts("== Integers")

    benchmark(column_count, row_count, fn ->
      Exceed.Worksheet.new("Sheet Name", headers, integers)
      |> Exceed.Worksheet.to_xml()
      |> Exceed.File.file("xl/worksheets/sheet1.xml", opts)
      |> List.wrap()
      |> Zstream.zip()
      |> Stream.run()
    end)

    IO.puts("== Binary")

    benchmark(column_count, row_count, fn ->
      Exceed.Worksheet.new("Sheet Name", headers, binaries)
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

  def integer_stream(column_count, row_count) do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.chunk_every(column_count)
    |> Stream.take(row_count)
  end

  def binary_stream(column_count, row_count) do
    Stream.unfold(?A, fn char ->
      {chars, next} = take_chars(char, Enum.random(10..20), [])
      {to_string(chars), next}
    end)
    |> Stream.chunk_every(column_count)
    |> Stream.take(row_count)
  end

  defp take_chars(char, 0, acc), do: {Enum.reverse(acc), char}

  defp take_chars(char, n, acc) do
    next = if char >= 0xD7FF, do: ?A, else: char + 1
    take_chars(next, n - 1, [char | acc])
  end
end
