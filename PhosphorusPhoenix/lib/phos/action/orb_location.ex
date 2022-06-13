defmodule Phos.Action.Orb_Location do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Orb, Location}

  @primary_key false
  schema "orbs_location" do
    belongs_to :orbs, Orb, type: Ecto.UUID, references: :id, foreign_key: :orb_id
    belongs_to :locations, Location, type: :integer, references: :id, foreign_key: :location_id

    timestamps()
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:orb_id, :location_id])
    |> validate_required([:orb_id, :location_id])
    |> unique_constraint([:orb_id, :location_id],
      name: :orb_id_location_id_unique_index,
      message: "ALREADY_EXISTS"
    )
    |> unique_constraint(:location_overload, name: :same_orb_within_location)
  end
end
