defmodule Phos.Users.Private_Profile do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Users.{User, Geolocation}

  @primary_key {:user_id, Ecto.UUID, autogenerate: false}
  schema "private_profile" do
    embeds_many :geolocation, Geolocation, on_replace: :delete

    belongs_to :users, User, foreign_key: :user_id, primary_key: true, define_field: false

    field :user_token, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_id])
    |> cast_embed(:geolocation)
  end
end
