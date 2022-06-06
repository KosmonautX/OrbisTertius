defmodule Phos.Users.Userprofile do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :birthday, :naive_datetime
    field :bio, :string
  end

  @doc false
  def changeset(userp, attrs) do
    userp
    |> cast(attrs, [:birthday, :bio])
  end
end
