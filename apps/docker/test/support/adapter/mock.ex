defmodule Staxx.Docker.Adapter.Mock do
  @moduledoc """
  Set of docker commands that will be running on read docker daemon
  """
  @behaviour Staxx.Docker

  require Logger

  alias Staxx.Docker.Container

  @impl true
  def start(_id), do: :ok

  @impl true
  def run(%Container{name: name} = container),
    do: {:ok, %Container{container | id: name}}

  @impl true
  def run_sync(%Container{}), do: "ok"

  @impl true
  def logs(_id), do: ""

  @impl true
  def rm(_id), do: :ok

  @impl true
  def stop(""), do: {:error, "No container id passed"}
  def stop(_container_id), do: :ok

  @impl true
  def create_network(id), do: {:ok, id}

  @impl true
  def rm_network(_id), do: :ok

  @impl true
  def prune_networks(), do: :ok

  @impl true
  def join_network(id, _container_id), do: {:ok, id}
end
