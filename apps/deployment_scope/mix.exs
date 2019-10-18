defmodule Staxx.DeploymentScope.MixProject do
  use Mix.Project

  def project do
    [
      app: :deployment_scope,
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
      mod: {Staxx.DeploymentScope.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]
  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:event_stream, in_umbrella: true},
      {:proxy, in_umbrella: true},
      {:poison, "~> 3.1.0"},
      {:faker, "~> 0.12", only: :test},
      {:ex_machina, "~> 2.3", only: :test}
    ]
  end
end
