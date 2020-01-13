defmodule Staxx.Testchain.Factory do
  alias Staxx.Testchain
  alias Staxx.Testchain.SnapshotDetails
  alias Staxx.Testchain.EVM.{Config}

  @doc """
  Builds and returns randomly filled SnapshotDetails struct.
  First parameter is the Testchain.evm_type, default value is :ganache
  """
  @spec build_snapshot_details(any) :: SnapshotDetails.t()
  def build_snapshot_details(chain_type \\ :ganache) do
    %SnapshotDetails{
      id: Faker.UUID.v4(),
      description: Faker.String.base64(),
      path: Faker.String.base64(),
      chain: chain_type,
      date: DateTime.utc_now()
    }
  end

  def build_evm_config(type \\ :geth) do
    id = Testchain.unique_id()

    %Config{
      id: id,
      type: type,
      description: Faker.String.base64(),
      clean_on_stop: true,
      db_path: Testchain.evm_db_path(id)
    }
  end
end
