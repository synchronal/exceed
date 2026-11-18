defmodule Exceed.Datetime do
  @moduledoc false

  def local(%DateTime{} = value),
    do: {DateTime.to_naive(value), value.utc_offset + value.std_offset}

  def local(value), do: {value, nil}

  def format(nil, _offset), do: nil

  def format(code, nil) do
    code
    |> String.replace("{offset}", "")
    |> String.trim()
  end

  def format(code, offset) do
    if String.contains?(code, "{offset}") do
      sign = if offset < 0, do: "-", else: "+"

      hours =
        offset
        |> abs()
        |> div(3600)
        |> Integer.to_string()
        |> String.pad_leading(2, "0")

      minutes =
        offset
        |> abs()
        |> rem(3600)
        |> div(60)
        |> Integer.to_string()
        |> String.pad_leading(2, "0")

      String.replace(code, "{offset}", ~s("#{sign}#{hours}#{minutes}"))
    else
      code
    end
  end
end
