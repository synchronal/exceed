defmodule Exceed.MixProject do
  use Mix.Project

  @scm_url "https://github.com/synchronal/exceed"
  @version "0.3.0"

  def application,
    do: [
      extra_applications: [:logger]
    ]

  def cli,
    do: [
      preferred_envs: [credo: :test, docs: :docs, dialyzer: :test]
    ]

  def project,
    do: [
      app: :exceed,
      deps: deps(),
      description: "A high-level stream-oriented MS Excel OpenXML (`.xlsx`) generator",
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: @scm_url,
      name: "Exceed",
      package: package(),
      source_url: @scm_url,
      start_permanent: Mix.env() == :prod,
      version: @version
    ]

  # # #

  defp deps,
    do: [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:decimal, "~> 2.1", optional: true},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: [:docs, :dev], runtime: false},
      {:mix_audit, "~> 2.0", only: :dev, runtime: false},
      {:moar, "~> 1.50", only: :test},
      {:xlsx_reader, "~> 0.8", only: :test},
      {:xml_query, "~> 0.2", only: :test},
      {:xml_stream, "~> 0.3"},
      {:zstream, "~> 0.6.4"}
    ]

  defp dialyzer,
    do: [
      plt_add_apps: [:ex_unit, :mix],
      plt_add_deps: :app_tree
    ]

  defp docs,
    do: [
      main: "readme",
      extras: ["README.md", "LICENSE.md"],
      groups_for_modules: [
        Protocols: [Exceed.Worksheet.Cell],
        Utilities: [Exceed.Util]
      ]
    ]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package,
    do: [
      licenses: ["MIT"],
      maintainers: ["synchronal.dev", "Erik Hanson", "Eric Saxby"],
      links: %{"GitHub" => @scm_url}
    ]
end
