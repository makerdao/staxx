defmodule DeploymentScope.MixProject do
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
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DeploymentScope.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:proxy, in_umbrella: true},
      {:stacks, in_umbrella: true}
    ]
  end
end
