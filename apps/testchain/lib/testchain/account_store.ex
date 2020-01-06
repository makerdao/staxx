defmodule Staxx.Testchain.AccountStore do
  @moduledoc """
  Account storage functions.
  It will store list of account for chain with their private keys.

  Needed for snapshoting. To be able to restore accounts/priv keys after snapshot restorage
  """

  alias Staxx.Testchain.Helper

  # file where list of initial accounts will be stored
  @file_name "initial_addresses"

  @doc """
  Store list of accounts into `{db_path}/addresses.json` file
  """
  @spec store(binary, [map]) :: :ok | {:error, term()}
  def store(db_path, list) do
    db_path
    |> Path.join(@file_name)
    |> Helper.write_term_to_file(list)
  end

  @doc """
  Load list of initial accounts from chain `{db_path}/accounts.json`
  """
  @spec load(binary) :: {:ok, [map]} | {:error, term()}
  def load(db_path) do
    db_path
    |> Path.join(@file_name)
    |> Helper.read_term_from_file()
  end

  @doc """
  Checks if file with list of accounts exist
  """
  @spec exists?(binary) :: boolean()
  def exists?(db_path) do
    db_path
    |> Path.join(@file_name)
    |> File.exists?()
  end
end
