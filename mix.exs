defmodule TestchainBackend.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:distillery, "~> 2.0"},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:ex_testchain, github: "makerdao/ex_testchain", branch: "master", runtime: false},
      {:testchain_dockerservice,
       github: "makerdao/testchain-dockerservice", branch: "master", runtime: false}
      # {:testchain_dockerservice, path: "../testchain-dockerservice", runtime: false}
    ]
  end
end
