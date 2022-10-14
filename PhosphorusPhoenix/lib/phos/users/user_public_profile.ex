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
    field :banner_pic, :integer, default: :rand.uniform(7)
    field :profile_pic, :integer, default: :rand.uniform(7)
    field :traits, {:array, :string}, default: []
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:birthday, :public_name, :bio, :occupation, :honorific, :traits, :profile_pic, :banner_pic])
    |> validate_inclusion(:honorific, ["Mr", "Ms", "Dr"])
  end
end
