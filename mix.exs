defmodule RaiEx.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rai_ex,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: docs(),
      source_url: "https://github.com/willHol/rai_ex",
      name: "RaiEx"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpoison],
      mod: {RaiEx.Application, []}
    ]
  end

  def docs do
    [
      extras: ["README.md"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:httpoison, "~> 0.13.0"},
      {:ex_doc, "~> 0.16.2", only: :dev, runtime: false},
      {:decimal, "~> 1.4"},
      {:blake2, "~> 1.0"}
    ]
  end
end
