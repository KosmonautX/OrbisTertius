defmodule Phos.Users.Geohash do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :type, :string
    field :location_description, :string
    field :geohash, :integer
    field :radius, :integer
    field :geohashingtiny, :integer
    field :chronolock, :integer
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:type, :location_description, :geohash, :radius, :geohashingtiny, :chronolock])
  end
end
