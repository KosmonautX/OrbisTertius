defmodule Phos.Users.Public_Profile do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Users.{User}

  @primary_key {:user_id, Ecto.UUID, autogenerate: false}
  schema "public_profile" do
    field :birthday, :naive_datetime
    field :bio, :string

    belongs_to :users, User, foreign_key: :user_id, primary_key: true, define_field: false

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_id, :birthday, :bio])
  end
end
