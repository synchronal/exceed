defmodule Exceed.Xml do
  @moduledoc false

  # A printer for XmlStream that produces fewer nested iodata by using string
  # interpolation.

  alias XmlStream.Printer, as: P
  @behaviour XmlStream.Printer

  def init(_), do: nil

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
    {["<#{P.encode_name(name)}#{P.attrs_to_string(attrs)}/>"], nil}
  end

  def print({:const, value}, _) do
    {[escape_binary(to_string(value))], nil}
  end

  # # #

  defp attrs_to_string(attrs) do
    Enum.reduce(attrs, <<>>, fn {key, value}, acc ->
      acc <> " " <> P.encode_name(key) <> ~s(=") <> escape_binary(to_string(value)) <> ~s(")
    end)
  end

  defp escape_binary(""), do: ""
  defp escape_binary("&" <> rest), do: "&amp;" <> escape_binary(rest)
  defp escape_binary("\"" <> rest), do: "&quot;" <> escape_binary(rest)
  defp escape_binary("'" <> rest), do: "&apos;" <> escape_binary(rest)
  defp escape_binary("<" <> rest), do: "&lt;" <> escape_binary(rest)
  defp escape_binary(">" <> rest), do: "&gt;" <> escape_binary(rest)
  defp escape_binary(<<char::utf8>> <> rest), do: <<char::utf8>> <> escape_binary(rest)
end
