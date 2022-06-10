defmodule Phos.Users.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Orb}
  alias Phos.Users.{Fyr, Geohash, Profile}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "users" do
    field :email, :string
    field :username, :string
    field :media, :boolean, default: false
    field :profile_pic, :integer, default: :rand.uniform(6)
    field :fyr_id, :string

    field :password, :string, virtual: true
    field :password_hash, :string

    has_many :orbs, Orb
    embeds_one :userprofile, Profile
    embeds_many :geohash, Geohash

    timestamps()
  end

  @doc false
  def changeset(%Phos.Users.User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :media, :profile_pic, :fyr_id, :email, :password])
    |> validate_required(:email)
    |> cast_embed(:userprofile)
    |> cast_embed(:geohash)
    |> verify_password()
  end

  defp verify_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Argon2.add_hash(password))
  end
  defp verify_password(changeset), do: changeset
end
