defmodule Stacks.MixProject do
  use Mix.Project

  def project do
    [
      app: :stacks,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Stacks.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:docker, in_umbrella: true},
      {:proxy, in_umbrella: true},
      {:event_bus, in_umbrella: true},
      {:yaml_elixir, "~> 2.1"},
      {:poison, "~> 3.1"},
      {:telemetry, "~> 0.4.0", override: true}
    ]
  end
end
