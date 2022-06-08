defmodule Phos.Users.Private_Profile do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Users.{User, Geohash}

  @primary_key {:user_id, Ecto.UUID, autogenerate: false}
  schema "private_profile" do
    embeds_many :geohash, Geohash

    belongs_to :users, User, foreign_key: :user_id, primary_key: true, define_field: false

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_id])
    |> cast_embed(:geohash)
  end
end
