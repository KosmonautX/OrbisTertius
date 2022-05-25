defmodule Phos.Action.Orb_Orb_Location do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Orb_Emb, Orb_Location}

  @primary_key false
  @foreign_key_type :binary_id
  schema "orbs_orb_location" do
    belongs_to :orbs_emb, Orb_Emb
    belongs_to :orbs_location, Orb_Location

    timestamps()
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:orb_id, :location_id])
    |> validate_required([:orb_id, :location_id])
  end
end
