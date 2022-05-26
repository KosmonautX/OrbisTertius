defmodule Phos.Action.Location do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Orb, Orb_Location}

  @primary_key {:location_id, :integer, autogenerate: false}
  schema "locations" do
    many_to_many :orbs, Orb, join_through: Orb_Location, join_keys: [location_id: :location_id, orb_id: :orb_id]

    timestamps()
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:location_id])
  end
end
