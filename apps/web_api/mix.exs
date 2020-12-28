defmodule Staxx.WebApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :web_api,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Staxx.WebApi.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:instance, in_umbrella: true},
      {:event_stream, in_umbrella: true},
      {:store, in_umbrella: true},
      {:testchain, in_umbrella: true},
      {:phoenix, "~> 1.5"},
      {:phoenix_pubsub, "~> 2.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:plug, "~> 1.11"},
      {:plug_cowboy, "~> 2.4"},
      {:corsica, "~> 1.1"},
      {:faker, "~> 0.12", only: :test},
      {:ex_machina, "~> 2.3", only: :test},
      {:ex_json_schema, "~> 0.7.3"}
    ]
  end
end
