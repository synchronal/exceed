defmodule Exceed.File do
  @moduledoc false

  @buffer_size_bytes 128 * 1024
  @accumulator {[], 0}

  def file(content, filename, opts) do
    stream = XmlStream.stream!(content, printer: Exceed.Xml)
    stream = if Keyword.get(opts, :buffer, true), do: buffer(stream), else: stream
    Zstream.entry(filename, stream)
  end

  defp buffer(stream) do
    stream
    |> Stream.chunk_while(
      @accumulator,
      fn chunk, {acc, length} ->
        length = length + IO.iodata_length(chunk)
        acc = [acc | chunk]

        if length >= @buffer_size_bytes do
          {:cont, IO.iodata_to_binary(acc), @accumulator}
        else
          {:cont, {acc, length}}
        end
      end,
      fn
        {[], _} -> {:cont, [], @accumulator}
        {acc, _} -> {:cont, IO.iodata_to_binary(acc), @accumulator}
      end
    )
  end
end
