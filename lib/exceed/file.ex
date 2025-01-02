defmodule Exceed.File do
  @moduledoc false

  @buffer_size_bytes 16 * 1024

  def file(content, filename, opts) do
    stream = XmlStream.stream!(content, printer: XmlStream.Printer.Ugly)
    stream = if Keyword.get(opts, :buffer, true), do: buffer(stream), else: stream
    Zstream.entry(filename, stream)
  end

  defp buffer(stream) do
    stream
    |> Stream.chunk_while(
      [],
      fn chunk, acc ->
        acc = [chunk | acc]

        if IO.iodata_length(acc) > @buffer_size_bytes do
          {:cont, IO.iodata_to_binary(Enum.reverse(acc)), []}
        else
          {:cont, acc}
        end
      end,
      fn
        [] -> {:cont, []}
        acc -> {:cont, IO.iodata_to_binary(Enum.reverse(acc)), []}
      end
    )
  end
end
