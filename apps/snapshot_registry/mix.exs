defmodule Staxx.SnapshotRegistry.MixProject do
  use Mix.Project

  def project do
    [
      app: :snapshot_registry,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Staxx.SnapshotRegistry.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:utils, in_umbrella: true},
      {:transport, in_umbrella: true},
      {:ecto_sql, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:plug_cowboy, "~> 2.0"},
      {:joken, "~> 2.0"},
      {:jason, "~> 1.1"}
    ]
  end
end
