defmodule Staxx.Store.Models.ChainEvent do
  @moduledoc """
  Chan model implementation
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Staxx.Store.Repo
  alias Staxx.Store.Models.Chain

  @type t :: %__MODULE__{
          id: pos_integer,
          chain_uuid: binary,
          event: binary,
          data: map | nil
        }

  @derive Jason.Encoder

  # @primary_key {:uuid, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "chain_events" do
    field(:event, :string)
    field(:data, :map, default: %{})

    belongs_to(:chain, Chain,
      foreign_key: :chain_uuid,
      references: :uuid
    )

    timestamps()
  end

  @fields [
    :chain_uuid,
    :event,
    :data
  ]

  @doc """
  Changeset for user model
  """
  @spec changeset(t(), map) :: Ecto.Changeset.t()
  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:chain_uuid, :event])
  end

  @doc """
  Create new user in system
  """
  @spec create(map) :: {:ok, t()} | {:error, term}
  def create(data) do
    %__MODULE__{}
    |> changeset(data)
    |> Repo.insert()
  end

  @doc """
  Udpate user in system
  """
  @spec update(t(), map) :: {:ok, t()} | {:error, term}
  def update(%__MODULE__{} = user, data) do
    user
    |> changeset(data)
    |> Repo.insert_or_update()
  end

  @doc """
  Load user from DB
  """
  @spec get(pos_integer) :: t() | nil
  def get(id) do
    __MODULE__
    |> Repo.get(id)
  end

  @doc """
  List all users based on limits
  """
  @spec list(pos_integer, pos_integer) :: [t()]
  def list(limit \\ 50, offset \\ 0) do
    __MODULE__
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end
end
