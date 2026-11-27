defmodule Exceed.Stylesheet do
  @moduledoc false

  alias XmlStream, as: Xs

  @defaults [date: "yyyy-mm-dd", datetime: "yyyy-mm-dd hh:mm:ss"]

  def config(styles, formats) do
    styles =
      Enum.map(styles, fn {name, opts} ->
        unless is_atom(name) and name not in [nil, false],
          do: raise(ArgumentError, "style names must be atoms other than nil or false, got: #{inspect(name)}")

        {name, style_options(opts)}
      end)

    if length(Enum.uniq_by(styles, &elem(&1, 0))) != length(styles),
      do: raise(ArgumentError, "style names must be unique")

    formats = Enum.to_list(formats)

    for {name, format} <- formats do
      unless is_atom(name) and name not in [nil, false] and is_binary(format),
        do: raise(ArgumentError, "formats must map atom names (except nil and false) to strings")
    end

    if length(Enum.uniq_by(formats, &elem(&1, 0))) != length(formats),
      do: raise(ArgumentError, "format names must be unique")

    # Keep the built-in date/datetime indices (1 and 2), including format overrides.
    defaults = Enum.map(@defaults, fn {name, code} -> {name, Keyword.get(formats, name, code)} end)

    formats =
      [{nil, nil}] ++
        defaults ++
        Keyword.drop(formats, Keyword.keys(@defaults))

    styles = [{nil, []}] ++ styles
    # Preserve numeric protocol style indices from the declaration order.
    names =
      for {style, opts} <- styles, {format, _} <- formats do
        {format, if(is_nil(style), do: nil, else: opts)}
      end

    %{
      formats: Map.new(formats),
      styles: Map.new(styles),
      cell_xfs: names |> Enum.with_index() |> Map.new(fn {names, index} -> {index, names} end)
    }
  end

  def style_options(opts) do
    opts = Keyword.validate!(opts, [:bold, :bg_color, :border, :align, :valign, :wrap_text])

    for {key, allowed} <- [
          bold: [true, false],
          wrap_text: [true, false],
          border: [:thin],
          align: [:left, :center, :right],
          valign: [:top, :center, :bottom]
        ],
        Keyword.has_key?(opts, key) and opts[key] not in allowed do
      raise ArgumentError, "#{key} must be one of #{inspect(allowed)}"
    end

    opts = if Keyword.has_key?(opts, :bg_color), do: Keyword.update!(opts, :bg_color, &color!/1), else: opts
    Enum.sort(opts)
  end

  def open(config) do
    registry = :ets.new(__MODULE__, [:set, :private])
    for format <- [nil, :date, :datetime], do: register(registry, format, nil, nil, config)
    registry
  end

  def close(registry), do: :ets.delete(registry)

  def register(registry, format, style, offset, config) do
    code = Map.get(config.formats, format, format)
    key = {code, style, offset}

    case :ets.lookup(registry, key) do
      [{_, index}] ->
        index

      [] ->
        code = Exceed.Datetime.format(code, offset)
        opts = [num_format: code] ++ (style || [])
        index = :ets.update_counter(registry, :next, 1, {:next, -1})
        :ets.insert(registry, [{key, index}, {{:xf, index}, opts}])
        index
    end
  end

  def to_xml(registry) do
    registry
    |> :ets.match_object({{:xf, :_}, :_})
    |> Enum.sort_by(fn {{:xf, index}, _} -> index end)
    |> Enum.map(&elem(&1, 1))
    |> build_xml()
  end

  def to_xml, do: build_xml(Enum.map([nil | Keyword.values(@defaults)], &[num_format: &1]))

  # # #

  defp build_xml(styles) do
    formats = values(styles, :num_format)
    format_ids = formats |> Enum.with_index(164) |> Map.new()
    colors = values(styles, :bg_color)
    fill_ids = colors |> Enum.with_index(2) |> Map.new()

    [
      Xs.declaration(version: "1.0", encoding: "UTF-8", standalone: "yes"),
      Xs.element("styleSheet", %{"xmlns" => Exceed.Namespace.main()}, [
        collection(
          "numFmts",
          for {format, id} <- Enum.with_index(formats, 164) do
            Xs.empty_element("numFmt", %{"numFmtId" => id, "formatCode" => format})
          end
        ),
        collection("fonts", [Xs.empty_element("font"), Xs.element("font", Xs.empty_element("b"))]),
        collection("fills", [
          fill("none"),
          fill("gray125")
          | for color <- colors do
              fill("solid", [
                Xs.empty_element("fgColor", %{"rgb" => color}),
                Xs.empty_element("bgColor", %{"indexed" => 64})
              ])
            end
        ]),
        collection("borders", [border(%{}), border(%{"style" => "thin"})]),
        collection("cellXfs", Enum.map(styles, &xf(&1, format_ids, fill_ids))),
        Xs.element(
          "tableStyles",
          %{"count" => "0", "defaultPivotStyle" => "PivotStyleLight16", "defaultTableStyle" => "TableStyleMedium9"},
          []
        )
      ])
    ]
  end

  defp values(styles, key), do: Enum.uniq(for opts <- styles, value = opts[key], do: value)

  defp collection(name, elements),
    do: Xs.element(name, %{"count" => length(elements)}, elements)

  defp fill(pattern, content \\ []),
    do: Xs.element("fill", Xs.element("patternFill", %{"patternType" => pattern}, content))

  defp border(attrs) do
    Xs.element("border", [
      Enum.map(~w(left right top bottom), &Xs.empty_element(&1, attrs)),
      Xs.empty_element("diagonal")
    ])
  end

  defp xf(opts, format_ids, fill_ids) do
    attrs = %{
      "numFmtId" => Map.get(format_ids, opts[:num_format], 0),
      "fontId" => if(opts[:bold], do: 1, else: 0),
      "fillId" => Map.get(fill_ids, opts[:bg_color], 0),
      "borderId" => if(opts[:border] == :thin, do: 1, else: 0),
      "xfId" => 0,
      "applyNumberFormat" => 1,
      "applyFont" => 1,
      "applyFill" => 1,
      "applyBorder" => 1,
      "applyAlignment" => 1
    }

    alignment =
      for {key, attr} <- [align: "horizontal", valign: "vertical", wrap_text: "wrapText"],
          {:ok, value} <- [Keyword.fetch(opts, key)],
          into: %{},
          do: {attr, value}

    Xs.element("xf", attrs, Xs.empty_element("alignment", alignment))
  end

  defp color!(color) do
    if is_binary(color) and Regex.match?(~r/\A#?[0-9a-fA-F]{6}\z/, color) do
      "FF" <> (color |> String.trim_leading("#") |> String.upcase())
    else
      raise ArgumentError, "bg_color must be a six-digit RGB color, got: #{inspect(color)}"
    end
  end
end
