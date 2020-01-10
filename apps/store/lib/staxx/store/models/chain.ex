defmodule Staxx.Store.Models.Chain do
  @moduledoc """
  Chan model implementation
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Staxx.Store.Repo
  alias Staxx.Store.Models.User

  @type t :: %__MODULE__{
          # user_id: pos_integer | nil,
          chain_id: binary,
          title: binary,
          node_type: atom | binary,
          status: atom | binary,
          config: map,
          details: map,
          deployment: map
        }

  @derive {Jason.Encoder,
           only: [:chain_id, :title, :node_type, :status, :config, :details, :deployment]}

  @primary_key {:chain_id, :string, []}
  schema "chains" do
    field(:title, :string)
    field(:node_type, :string)
    field(:status, :string, default: "initializing")
    field(:config, :map, default: %{})
    field(:details, :map, default: %{})
    field(:deployment, :map, default: %{})

    belongs_to(:user, User)

    timestamps()
  end

  @fields [
    :user_id,
    :chain_id,
    :title,
    :node_type,
    :status,
    :config,
    :details,
    :deployment
  ]

  @doc """
  Changeset for user model
  """
  @spec changeset(t(), map) :: Ecto.Changeset.t()
  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:chain_id, :node_type])
    |> unique_constraint(:chain_id)
  end

  @doc """
  Set field for chain
  """
  @spec set(binary, map) :: {:ok, t()} | {:error, term}
  def set(id, params) do
    case get(id) do
      nil ->
        {:error, :not_found}

      chain ->
        chain
        |> changeset(params)
        |> Repo.update()
    end
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
  Load user from DB
  """
  @spec get(binary) :: t() | nil
  def get(id) do
    __MODULE__
    |> Repo.get(id)
  end

  @doc """
  List all chains based on user_id
  """
  @spec list(pos_integer | nil, pos_integer, pos_integer) :: [t()]
  def list(user_id \\ nil, limit \\ 50, offset \\ 0)

  def list(nil, limit, offset) do
    __MODULE__
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  def list(user_id, limit, offset) do
    __MODULE__
    |> where(user_id: ^user_id)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Delete chain from DB
  """
  @spec delete(binary) :: {integer(), nil | [term()]}
  def delete(id) do
    __MODULE__
    |> where(chain_id: ^id)
    |> Repo.delete_all()
  end

  @doc """
  Create new chain record or updates existing
  """
  @spec insert_or_update(binary, map()) :: {:ok, t()} | {:error, term}
  def insert_or_update(id, data) do
    id
    |> get()
    |> case do
      nil ->
        %__MODULE__{chain_id: id}

      chain ->
        chain
    end
    |> changeset(data)
    |> Repo.insert_or_update()
  end

  @doc """
  Rewrite chain config, details and deployment data
  """
  @spec rewrite(binary, t()) :: {integer(), nil | [term()]}
  def rewrite(id, %__MODULE__{config: config, details: details, deployment: deployment}) do
    __MODULE__
    |> where(chain_id: ^id)
    |> update(set: [config: ^config, details: ^details, deployment: ^deployment])
    |> Repo.update_all([])
  end

  @doc """
  Updates status for chain
  """
  @spec set_status(binary, atom | binary, map()) :: {integer(), nil | [term()]}
  def set_status(id, status, data \\ %{})

  def set_status(id, status, data) when is_atom(status),
    do: set_status(id, Atom.to_string(status), data)

  def set_status(id, status, _data) do
    __MODULE__
    |> where(chain_id: ^id)
    |> update(set: [status: ^status])
    |> Repo.update_all([])
  end
end
