defmodule Kurenai.MixProject do
  use Mix.Project

  def project do
    [
      app: :kurenai,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Kurenai, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:alchemy, "~> 0.6", hex: :discord_alchemy},
      {:companion_ex, "~> 0.1"}
    ]
  end
end
