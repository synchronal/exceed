defmodule Exceed.MixProject do
  use Mix.Project

  @version "0.1.0"

  def application,
    do: [
      extra_applications: [:logger]
    ]

  def project,
    do: [
      app: :exceed,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]

  # # #

  defp deps,
    do: [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28", only: [:docs, :dev], runtime: false},
      {:mix_audit, "~> 2.0", only: :dev, runtime: false}
    ]
end
