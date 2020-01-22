defmodule Staxx.Store.Factory do
  alias Faker

  @doc """
  Builds and returns randomly filled SnapshotDetails struct.
  First parameter is the Testchain.evm_type, default value is :ganache
  """
  @spec build_snapshot_details(any) :: map()
  def build_snapshot_details(chain_type \\ :ganache) do
    %{
      id: Faker.UUID.v4(),
      description: Faker.String.base64(),
      path: Faker.String.base64(),
      chain: chain_type,
      date: DateTime.utc_now()
    }
  end
end
