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
    field :banner_pic, :integer, default: :rand.uniform(6)
    field :profile_pic, :integer, default: :rand.uniform(6)
    field :traits, {:array, :string}, default: []
    field :territories, {:array, :integer}, default: []
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:birthday, :public_name, :bio, :occupation, :honorific, :banner_pic, :profile_pic, :traits])
    |> validate_inclusion(:honorific, ["Mr", "Ms", "Dr"])
  end


  def territorial_changeset(user, attrs) do
    user
    |> cast(attrs, Phos.Users.Public_Profile.__schema__(:fields))
    |> validate_inclusion(:honorific, ["Mr", "Ms", "Dr"])
  end

end
