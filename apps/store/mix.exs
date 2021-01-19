defmodule Staxx.Store.MixProject do
  use Mix.Project

  def project do
    [
      app: :store,
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

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["test/support" | elixirc_paths()]
  defp elixirc_paths(_), do: elixirc_paths()
  defp elixirc_paths, do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Staxx.Store.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:event_stream, in_umbrella: true},
      {:ecto_sql, "~> 3.5"},
      {:postgrex, ">= 0.0.0"},
      {:faker, "~> 0.11", only: :test}
    ]
  end
end
