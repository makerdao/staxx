defmodule Stax.EventStream.MixProject do
  use Mix.Project

  def project do
    [
      app: :event_stream,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Stax.EventStream.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:event_bus, "~> 1.6.0"},
      {:uuid, "~> 1.1"},
      {:gnat, "~> 0.6.1"},
      {:jason, "~> 1.1"},
      {:faker, "~> 0.12", only: :test}
    ]
  end
end
