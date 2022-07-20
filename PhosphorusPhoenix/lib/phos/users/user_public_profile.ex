defmodule Phos.Users.User_Public_Profile do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Users.{User}

  @primary_key false
  embedded_schema do
    field :birthday, :naive_datetime
    field :bio, :string
    field :occupation, :string
    field :pronouns, :string

  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:birthday, :bio, :occupation, :pronouns])
  end
end
