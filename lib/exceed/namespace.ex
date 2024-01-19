defmodule Exceed.Namespace do
  @moduledoc false

  def content_types, do: "http://schemas.openxmlformats.org/package/2006/content-types"
  def core_props, do: "http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
  def doc_props_vt, do: "http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"
  def doc_relationships, do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  def dublin_core, do: "http://purl.org/dc/elements/1.1/"
  def dublin_core_terms, do: "http://purl.org/dc/terms/"
  def dublin_core_type, do: "http://purl.org/dc/cdmitype/"
  def extended_properties, do: "http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
  def main, do: "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
  def relationships, do: "http://schemas.openxmlformats.org/package/2006/relationships"
  def schema_instance, do: "http://www.w3.org/2001/XMLSchema-instance"
end
