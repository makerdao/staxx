defmodule Staxx.Store.Models.User do
  @moduledoc """
  User model implementation
  """
  use Ecto.Schema

  require Logger

  import Ecto.Changeset
  import Ecto.Query

  alias Staxx.Store.Repo

  @type t :: %__MODULE__{
          email: binary,
          admin: boolean,
          active: boolean,
          name: binary,
          preferences: map
        }

  @derive {Jason.Encoder,
           only: [
             :id,
             :email,
             :active,
             :name,
             :preferences
           ]}

  schema "users" do
    field(:email, :string, unique: true)
    field(:admin, :boolean, default: false)
    field(:active, :boolean, default: true)
    field(:name, :string)
    field(:preferences, :map, default: %{})

    timestamps()
  end

  @fields [
    :email,
    :admin,
    :active,
    :name,
    :preferences
  ]

  @doc """
  Changeset for user model
  """
  @spec changeset(t(), map) :: Ecto.Changeset.t()
  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:email])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/\S+@\S+\.\S+/, message: "is invalid")
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
  Get user_id by email
  """
  @spec get_user_id(binary) :: nil | pos_integer
  def get_user_id(""), do: nil

  def get_user_id(nil), do: nil

  def get_user_id(email) do
    email
    |> by_email()
    |> case do
      nil ->
        %{email: email}
        |> create()
        |> case do
          {:ok, %__MODULE__{id: id}} ->
            id

          {:error, err} ->
            Logger.error(fn -> "Failed to create user record for #{email}: #{inspect(err)}" end)
            nil
        end

      %__MODULE__{id: id} ->
        id
    end
  end

  @doc """
  Load user by email
  """
  @spec by_email(binary) :: t() | nil
  def by_email(email) do
    __MODULE__
    |> Repo.get_by(email: email)
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
