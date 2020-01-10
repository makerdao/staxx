defmodule Staxx.Testchain.SnapshotManager do
  @moduledoc """
  Module that manages snapshoting by copy/paste chain DB folders.
  It could wrap everything to one archive file
  """
  require Logger

  alias Staxx.Testchain
  alias Staxx.Testchain.SnapshotDetails
  alias Staxx.Testchain.SnapshotStore

  # Snapshot taking/restoring timeout
  @timeout 30_000

  @doc """
  Check if given snapshot details are correct and snapshot actually exists
  """
  @spec exists?(SnapshotDetails.t()) :: boolean
  def exists?(%SnapshotDetails{path: path}), do: File.exists?(path)
  def exists?(_), do: false

  @doc """
  Create a snapshot and store it into local DB (DETS for now)
  """
  @spec make_snapshot(binary, Testchain.evm_type(), binary) ::
          {:ok, SnapshotDetails.t()} | {:error, term}
  def make_snapshot(from, chain_type, description \\ "") do
    Logger.debug(fn -> "Making snapshot for #{from} with description: #{description}" end)

    with true <- File.dir?(from),
         id <- generate_snapshot_id(),
         to <- build_path(id),
         false <- File.exists?(to),
         {:ok, _} <- async_compress(from, to) do
      {:ok,
       %SnapshotDetails{
         id: id,
         path: to,
         chain: chain_type,
         description: description,
         date: DateTime.utc_now()
       }}
    else
      false ->
        {:error, "path does not exist"}

      true ->
        {:error, "archive file already exist"}

      err ->
        err
    end
  end

  @doc """
  Restore snapshot to given path
  """
  @spec restore_snapshot(SnapshotDetails.t(), binary) :: :ok | {:error, term}
  def restore_snapshot(nil, _),
    do: {:error, "Wrong snapshot details passed"}

  def restore_snapshot(_, ""),
    do: {:error, "Wrong snapshot restore path passed"}

  def restore_snapshot(%SnapshotDetails{id: id, path: from}, to) do
    Logger.debug(fn -> "Restoring snapshot #{id} from #{from} to #{to}" end)

    unless File.exists?(to) do
      File.mkdir_p(to)
    end

    __MODULE__
    |> Task.async(:extract, [from, to])
    |> Task.await(@timeout)
    |> case do
      {:ok, _} ->
        :ok

      {:error, msg} ->
        {:error, msg}
    end
  end

  @doc """
  Compress given chain folder to `.tgz` archive
  Note: it will compress only content of given dir without full path !
  """
  @spec compress(binary, binary) :: {:ok, binary} | {:error, term()}
  def compress("", _), do: {:error, "Wrong input path"}
  def compress(_, ""), do: {:error, "Wrong output path"}

  def compress(from, to) do
    Logger.debug("Compressing path: #{from} to #{to}")

    # Building params for tar command
    params = ["-czvf", to, "-C", from, "."]

    with true <- String.ends_with?(to, ".tgz"),
         false <- File.exists?(to),
         {_, 0} <- System.cmd("tar", params, stderr_to_stdout: true) do
      {:ok, to}
    else
      false ->
        {:error, "Wrong name (must end with .tgz) for result archive #{to}"}

      true ->
        {:error, "Archive already exist: #{to}"}

      {err, status} ->
        {:error, "Failed with status: #{inspect(status)} and error: #{inspect(err)}"}

      res ->
        Logger.error(res)
        {:error, "Unknown error"}
    end
  end

  @doc """
  Extracts snapshot to given folder
  """
  @spec extract(binary, binary) :: {:ok, binary} | {:error, term()}
  def extract("", _), do: {:error, "Wrong path to snapshot passed"}
  def extract(_, ""), do: {:error, "Wrong extracting path for snapshot passed"}

  def extract(from, to) do
    Logger.debug(fn -> "Extracting #{from} to #{to}" end)

    # Building params for uncompressing tar
    params = ["-xzvf", from, "-C", to]

    unless File.exists?(to) do
      File.mkdir_p(to)
    end

    case System.cmd("tar", params, stderr_to_stdout: true) do
      {_, 0} ->
        {:ok, to}

      {err, status} ->
        {:error, "Failed with status: #{inspect(status)} and error: #{inspect(err)}"}
    end
  end

  @doc """
  Store new snapshot into local DB
  """
  @spec store(SnapshotDetails.t()) :: :ok | {:error, term()}
  def store(%SnapshotDetails{} = snapshot),
    do: SnapshotStore.store(snapshot)

  @doc """
  Create new snapshot record by given details and existing file
  """
  @spec upload(binary, Testchain.evm_type(), binary) :: {:ok, Details.t()} | {:error, term()}
  def upload(id, chain, description) do
    path = build_path(id)

    details = %SnapshotDetails{
      id: id,
      chain: chain,
      description: description,
      path: path
    }

    with {:exist, nil} <- {:exist, SnapshotStore.by_id(id)},
         true <- File.exists?(path),
         :ok <- SnapshotStore.store(details) do
      {:ok, details}
    else
      {:exist, _} ->
        {:error, "Snapshot already exist"}

      false ->
        {:error, "No snapshot file exist"}

      err ->
        err
    end
  end

  @doc """
  Load snapshot details by id
  In case of error it might raise an exception
  """
  @spec by_id(binary) :: SnapshotDetails.t() | nil
  def by_id(id), do: SnapshotStore.by_id(id)

  @doc """
  Load list of existing snapshots by chain type
  """
  @spec by_chain(Testchain.evm_type()) :: [SnapshotDetails.t()]
  def by_chain(chain), do: SnapshotStore.by_chain(chain)

  @doc """
  Remove snapshot details from local DB
  """
  @spec remove(binary) :: :ok
  def remove(id) do
    case by_id(id) do
      nil ->
        :ok

      %SnapshotDetails{path: path} ->
        if File.exists?(path) do
          File.rm(path)
        end

        # Remove from db
        SnapshotStore.remove(id)

        :ok
    end
  end

  @doc """
  Try to lookup for a key till new wouldn't be generated
  """
  @spec generate_snapshot_id() :: binary
  def generate_snapshot_id() do
    id = Testchain.unique_id()

    case SnapshotStore.by_id(id) do
      nil ->
        id

      _ ->
        generate_snapshot_id()
    end
  end

  # Build path by snapshot id
  defp build_path(id) do
    :testchain
    |> Application.get_env(:snapshot_base_path)
    |> Path.expand()
    |> Path.join("#{id}.tgz")
  end

  def async_compress(from, to) do
    __MODULE__
    |> Task.async(:compress, [from, to])
    |> Task.await(@timeout)
  end
end
