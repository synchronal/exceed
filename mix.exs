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
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]

  # # #

  defp deps,
    do: []
end
