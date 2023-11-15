defmodule Phos.Users.PublicProfile do
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
    embeds_many :places, Phos.Users.Geolocation, on_replace: :delete
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:birthday, :public_name, :bio, :occupation, :honorific, :banner_pic, :profile_pic, :traits])
    |> validate_inclusion(:honorific, ["Mr", "Ms", "Dr"])
  end


  def territorial_changeset(user, attrs) do
    user
    |> cast(attrs, [:territories])
    |> validate_inclusion(:honorific, ["Mr", "Ms", "Dr"])
    |> cast_embed(:places, with: &Phos.Users.Geolocation.places_changeset/2)
  end

end
