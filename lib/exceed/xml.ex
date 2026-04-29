defmodule Exceed.Xml do
  @moduledoc false

  # A printer for XmlStream that produces fewer nested iodata by using string
  # interpolation.

  alias XmlStream.Printer, as: P
  @behaviour XmlStream.Printer

  def init(_), do: nil

  @doc """
  XML tag printer, optimized for speed.
  """
  def print({:raw, iodata}, state), do: {iodata, state}

  def print({:open, name, attrs}, _) when attrs == %{} or attrs == [] do
    {["<#{P.encode_name(name)}>"], nil}
  end

  def print({:open, name, attrs}, _) do
    {["<#{P.encode_name(name)}#{attrs_to_string(attrs)}>"], nil}
  end

  def print({:close, name}, _) do
    {["</#{P.encode_name(name)}>"], nil}
  end

  def print({:decl, attrs}, _) do
    {["<?xml#{attrs_to_string(attrs)}?>"], nil}
  end

  def print({:pi, target, attrs}, _) when attrs == %{} do
    {["<?", P.pi_target_name(target), "?>"], nil}
  end

  def print({:pi, target, attrs}, _) do
    {["<?#{P.pi_target_name(target)}#{attrs_to_string(attrs)}?>"], nil}
  end

  def print({:comment, text}, _) do
    {["<!--#{P.encode_comment(text)}-->"], nil}
  end

  def print({:cdata, data}, _) do
    {["<![CDATA[#{P.escape_cdata(data)}]]>"], nil}
  end

  def print({:doctype, root_name, declaration}, _) do
    {["<!DOCTYPE ", P.encode_name(root_name), " ", declaration, ">"], nil}
  end

  def print({:empty_elem, name, attrs}, _) when attrs == %{} or attrs == [] do
    {["<#{P.encode_name(name)}/>"], nil}
  end

  def print({:empty_elem, name, attrs}, _) do
    {["<#{P.encode_name(name)}#{attrs_to_string(attrs)}/>"], nil}
  end

  def print({:const, value}, _) do
    {[escape_binary(to_string(value))], nil}
  end

  @doc false
  def escape_binary(binary) when is_binary(binary), do: escape_binary(binary, binary)

  @doc false
  def escape_cdata(binary) when is_binary(binary), do: escape_cdata(binary, binary, 0, 0)

  # # #

  defp attrs_to_string(attrs) do
    Enum.reduce(attrs, <<>>, fn {key, value}, acc ->
      acc <> " " <> P.encode_name(key) <> ~s(=") <> escape_binary(to_string(value)) <> ~s(")
    end)
  end

  # # #

  defp escape_binary(<<>>, original), do: original

  defp escape_binary(<<?&, rest::bits>>, original) do
    pos = byte_size(original) - byte_size(rest) - 1
    escape_binary(rest, original, pos + 1, 0, binary_part(original, 0, pos) <> "&amp;")
  end

  defp escape_binary(<<?", rest::bits>>, original) do
    pos = byte_size(original) - byte_size(rest) - 1
    escape_binary(rest, original, pos + 1, 0, binary_part(original, 0, pos) <> "&quot;")
  end

  defp escape_binary(<<?', rest::bits>>, original) do
    pos = byte_size(original) - byte_size(rest) - 1
    escape_binary(rest, original, pos + 1, 0, binary_part(original, 0, pos) <> "&apos;")
  end

  defp escape_binary(<<?<, rest::bits>>, original) do
    pos = byte_size(original) - byte_size(rest) - 1
    escape_binary(rest, original, pos + 1, 0, binary_part(original, 0, pos) <> "&lt;")
  end

  defp escape_binary(<<?>, rest::bits>>, original) do
    pos = byte_size(original) - byte_size(rest) - 1
    escape_binary(rest, original, pos + 1, 0, binary_part(original, 0, pos) <> "&gt;")
  end

  defp escape_binary(<<char, rest::bits>>, original) when char < 0x80,
    do: escape_binary(rest, original)

  defp escape_binary(<<_::utf8, rest::bits>>, original), do: escape_binary(rest, original)

  defp escape_binary(<<>>, _original, _skip, 0, acc), do: acc
  defp escape_binary(<<>>, original, skip, len, acc), do: acc <> binary_part(original, skip, len)

  defp escape_binary(<<?&, rest::bits>>, original, skip, 0, acc),
    do: escape_binary(rest, original, skip + 1, 0, acc <> "&amp;")

  defp escape_binary(<<?&, rest::bits>>, original, skip, len, acc),
    do:
      escape_binary(
        rest,
        original,
        skip + len + 1,
        0,
        acc <> binary_part(original, skip, len) <> "&amp;"
      )

  defp escape_binary(<<?", rest::bits>>, original, skip, 0, acc),
    do: escape_binary(rest, original, skip + 1, 0, acc <> "&quot;")

  defp escape_binary(<<?", rest::bits>>, original, skip, len, acc),
    do:
      escape_binary(
        rest,
        original,
        skip + len + 1,
        0,
        acc <> binary_part(original, skip, len) <> "&quot;"
      )

  defp escape_binary(<<?', rest::bits>>, original, skip, 0, acc),
    do: escape_binary(rest, original, skip + 1, 0, acc <> "&apos;")

  defp escape_binary(<<?', rest::bits>>, original, skip, len, acc),
    do:
      escape_binary(
        rest,
        original,
        skip + len + 1,
        0,
        acc <> binary_part(original, skip, len) <> "&apos;"
      )

  defp escape_binary(<<?<, rest::bits>>, original, skip, 0, acc),
    do: escape_binary(rest, original, skip + 1, 0, acc <> "&lt;")

  defp escape_binary(<<?<, rest::bits>>, original, skip, len, acc),
    do:
      escape_binary(
        rest,
        original,
        skip + len + 1,
        0,
        acc <> binary_part(original, skip, len) <> "&lt;"
      )

  defp escape_binary(<<?>, rest::bits>>, original, skip, 0, acc),
    do: escape_binary(rest, original, skip + 1, 0, acc <> "&gt;")

  defp escape_binary(<<?>, rest::bits>>, original, skip, len, acc),
    do:
      escape_binary(
        rest,
        original,
        skip + len + 1,
        0,
        acc <> binary_part(original, skip, len) <> "&gt;"
      )

  defp escape_binary(<<char, rest::bits>>, original, skip, len, acc) when char < 0x80,
    do: escape_binary(rest, original, skip, len + 1, acc)

  defp escape_binary(<<cp::utf8, rest::bits>>, original, skip, len, acc) when cp < 0x800,
    do: escape_binary(rest, original, skip, len + 2, acc)

  defp escape_binary(<<cp::utf8, rest::bits>>, original, skip, len, acc) when cp < 0x10000,
    do: escape_binary(rest, original, skip, len + 3, acc)

  defp escape_binary(<<_::utf8, rest::bits>>, original, skip, len, acc),
    do: escape_binary(rest, original, skip, len + 4, acc)

  # # #

  defp escape_cdata(<<>>, original, 0, _len), do: original
  defp escape_cdata(<<>>, original, skip, len), do: [binary_part(original, skip, len)]

  defp escape_cdata(<<"]]>", rest::bits>>, original, skip, 0),
    do: ["]]]]><![CDATA[>" | escape_cdata(rest, original, skip + 3, 0)]

  defp escape_cdata(<<"]]>", rest::bits>>, original, skip, len),
    do: [
      binary_part(original, skip, len),
      "]]]]><![CDATA[>" | escape_cdata(rest, original, skip + len + 3, 0)
    ]

  defp escape_cdata(<<char, rest::bits>>, original, skip, len) when char < 0x80,
    do: escape_cdata(rest, original, skip, len + 1)

  defp escape_cdata(<<cp::utf8, rest::bits>>, original, skip, len) when cp < 0x800,
    do: escape_cdata(rest, original, skip, len + 2)

  defp escape_cdata(<<cp::utf8, rest::bits>>, original, skip, len) when cp < 0x10000,
    do: escape_cdata(rest, original, skip, len + 3)

  defp escape_cdata(<<_::utf8, rest::bits>>, original, skip, len),
    do: escape_cdata(rest, original, skip, len + 4)
end
