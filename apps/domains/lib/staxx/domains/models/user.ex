defmodule Staxx.Domains.Models.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Staxx.Domains.Models.Organization

  @type t :: %__MODULE__{
          email: binary,
          name: binary,
          admin: boolean,
          active: boolean,
          preferences: %{}
        }

  schema "users" do
    field(:email, :string)
    field(:admin, :boolean, default: false)
    field(:active, :boolean, default: true)
    field(:name, :string)
    field(:preferences, :map, default: %{})

    belongs_to(:organization, Organization)
  end

  @fields [
    :email,
    :admin,
    :active,
    :name,
    :preferences
  ]

  @doc """
  Generate changeset for user model
  """
  @spec changeset(t(), map) :: Ecto.Changeset.t()
  def changeset(data, params) do
    data
    |> cast(params, @fields)
    |> validate_required([:email])
    |> update_change(:email, &String.downcase/1)
    |> validate_format(:email, ~r/\S+@\S+\.\S+/, message: "is invalid")
    |> unique_constraint(:email)
  end

  def changeset(params \\ %{}),
    do: changeset(%__MODULE__{}, params)
end
