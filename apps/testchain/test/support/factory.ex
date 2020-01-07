defmodule Staxx.Testchain.Factory do
  import Faker
  alias Staxx.Testchain.SnapshotDetails

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
end
