defmodule Staxx.EventStream.MixProject do
  use Mix.Project

  def project do
    [
      app: :event_stream,
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
      mod: {Staxx.EventStream.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:event_bus, "~> 1.6.1"},
      {:uuid, "~> 1.1"},
      {:gnat, "~> 1.2"},
      {:jason, "~> 1.1"},
      {:faker, "~> 0.12", only: :test}
    ]
  end
end
