defmodule Staxx.SnapshotRegistry.Models.Snapshot do
  @moduledoc """
  Snapshot model implementation in SnapshotRegistry
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Staxx.SnapshotRegistry.Repo

  @type t :: %__MODULE__{
          id: binary,
          description: binary,
          chain_type: binary
        }

  @primary_key {:id, :string, []}
  schema "snapshots" do
    field(:description, :string)
    field(:chain_type, :string)

    timestamps()
  end

  @fields [
    :id,
    :description,
    :chain_type
  ]

  @doc """
  Changeset for snapshots model
  """
  @spec changeset(t(), map) :: Ecto.Changeset.t()
  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:id])
    |> unique_constraint(:id)
  end

  @doc """
  Create new snapshot
  """
  @spec create(map) :: {:ok, t()} | {:error, term}
  def create(data) do
    %__MODULE__{}
    |> changeset(data)
    |> Repo.insert()
  end
end
