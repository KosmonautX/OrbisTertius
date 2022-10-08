defmodule Phos.Users.Public_Profile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :birthday, :naive_datetime
    field :public_name, :string
    field :bio, :string
    field :occupation, :string
    field :honorific, :string
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:birthday, :public_name, :bio, :occupation, :honorific])
    |> validate_inclusion(:honorific, ["Mr", "Ms", "Dr"])
  end
end
