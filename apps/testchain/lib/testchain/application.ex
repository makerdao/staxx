defmodule Staxx.Testchain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  alias Staxx.Testchain.EVM.Implementation.Geth.AccountsCreator
  alias Staxx.Utils

  def start(_type, _args) do
    check_erlang()
    check_snapshot_requirements()

    # List all child processes to be supervised
    children = [
      Staxx.Testchain.SnapshotStore,
      Staxx.Testchain.Deployment.Supervisor,
      {Registry, keys: :unique, name: Staxx.Testchain.EVMRegistry},
      :poolboy.child_spec(:worker, AccountsCreator.poolboy_config())
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Staxx.Testchain.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Check if we have everything ready for making snapshots
  defp check_snapshot_requirements() do
    unless System.find_executable("tar") do
      raise "Failed to initialize #{__MODULE__}: No tar executable found in system."
    end

    path =
      Application.get_env(:testchain, :snapshot_base_path)
      |> Path.expand()

    unless File.dir?(path) do
      :ok = Utils.mkdir_p(path)
    end
  end

  defp check_erlang() do
    if 21 > System.otp_release() |> String.to_integer() do
      Logger.error("Application requires Erlang OTP 21+ !")
    end

    if :lt == Version.compare(System.version(), "1.7.0") do
      Logger.error("Application required Elixir 1.7+ !")
    end
  end
end
