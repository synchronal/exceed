defmodule Exceed.MixProject do
  use Mix.Project

  @version "0.1.0"

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
      dialyzer: dialyzer(),
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      version: @version
    ]

  # # #

  defp deps,
    do: [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28", only: [:docs, :dev], runtime: false},
      {:mix_audit, "~> 2.0", only: :dev, runtime: false},
      {:moar, "~> 1.50", only: :test},
      {:xml_stream, "~> 0.2.0"},
      {:zstream, "~> 0.6.4"}
    ]

  defp dialyzer,
    do: [
      plt_add_apps: [:ex_unit, :mix],
      plt_add_deps: :app_tree
    ]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
