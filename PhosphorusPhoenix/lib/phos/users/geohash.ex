defmodule Phos.Users.Geohash do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key{:id, :string, autogenerate: false}
  embedded_schema do
    field :location_description, :string
    field :geohash, :integer
    field :chronolock, :integer
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:id, :location_description, :geohash, :chronolock])
  end
end
