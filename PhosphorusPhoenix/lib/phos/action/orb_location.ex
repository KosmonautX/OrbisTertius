defmodule Phos.Action.Orb_Location do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Orb_Emb, Orb_Orb_Location}

  @primary_key {:location_id, :string, autogenerate: false}
  schema "orbs_location" do

    many_to_many :orbs_emb, Orb_Emb, join_through: Orb_Orb_Location, join_keys: [location_id: :location_id, orb_id: :orb_id]

    timestamps()
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:location_id])
    # |> validate_required([:initiator, :acceptor])
  end
end
