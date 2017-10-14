defmodule RaiEx.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rai_ex,
      version: "0.2.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: description(),
      source_url: "https://github.com/willHol/rai_ex",
      name: "RaiEx"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpoison]
    ]
  end

  def docs do
    [
      extras: ["README.md"]
    ]
  end

  defp description() do
    "An Elixir client for managing a RaiBlocks node."
  end

  def package do
    [
      licenses: ["Apache 2.0"],
      maintainers: ["William Holmes"],
      links: %{"GitHub" => "https://github.com/willHol/rai_ex"},
      source_url: "https://github.com/willHol/rai_ex"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:httpoison, "~> 0.13.0"},
      {:ex_doc, "~> 0.16.2", only: :dev, runtime: false},
      {:decimal, "~> 1.4"},
      {:blake2, "~> 1.0"},
      {:ed25519, git: "https://github.com/willHol/ed25519_ex.git"}
    ]
  end
end
