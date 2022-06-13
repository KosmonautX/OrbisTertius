defmodule Phos.Users.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Orb}
  alias Phos.Users.{Geohash, Public_Profile, Private_Profile}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "users" do
    field :username, :string
    field :media, :boolean, default: false
    field :profile_pic, :integer, default: :rand.uniform(6)
    field :fyr_id, :string

    has_many :orbs, Orb
    has_one :public_profile, Public_Profile, references: :id, foreign_key: :user_id
    has_one :private_profile, Private_Profile, references: :id, foreign_key: :user_id

    timestamps()
  end

  @doc false
  def changeset(%Phos.Users.User{} = user, attrs) do
    user
    |> cast(attrs, [:id, :username, :media, :profile_pic, :fyr_id])
    |> cast_assoc(:public_profile)
    |> cast_assoc(:private_profile)
    |> unique_constraint(:username_taken, name: :unique_username)
  end
end
