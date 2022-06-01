defmodule Phos.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "users" do
    field :username, :string
    field :fyr_id, :string
    field :media, :string

    timestamps()
  end

  @doc false
  def changeset(%Phos.Users.User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :fyr_id, :media])
  end
end
