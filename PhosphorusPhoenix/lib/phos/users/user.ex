defmodule Phos.Users.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Orb}
  alias Phos.Users.{Fyr, Geohash, Userprofile}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "users" do
    field :username, :string
    field :media, :boolean, default: false
    field :profile_pic, :integer, default: :rand.uniform(6)
    field :fyr_id, :string

    has_many :orbs, Orb
    embeds_one :userprofile, Userprofile
    embeds_many :geohash, Geohash

    timestamps()
  end

  @doc false
  def changeset(%Phos.Users.User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :media, :profile_pic, :fyr_id])
    |> cast_embed(:userprofile)
    |> cast_embed(:geohash)
  end
end
