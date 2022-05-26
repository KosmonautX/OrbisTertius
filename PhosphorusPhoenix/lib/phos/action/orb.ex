defmodule Phos.Action.Orb do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Initiator, Location, Orb_Payload, Orb_Location}
  alias Phos.Repo

  @primary_key {:orb_id, Ecto.UUID, autogenerate: true}
  schema "orbs" do
    field :active, :boolean, default: false
    field :extinguish, :naive_datetime
    field :media, :boolean, default: false
    field :title, :string

    many_to_many :orbs_location, Location, join_through: Orb_Location, join_keys: [orb_id: :orb_id, location_id: :location_id]
    embeds_one :payload, Orb_Payload, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(%Phos.Action.Orb{} = orb, attrs) do
    orb
    |> cast(attrs, [:title, :active, :media, :extinguish])
    |> cast_assoc(:orbs_location)
    |> cast_embed(:payload)
    |> validate_required([:title, :active, :media, :extinguish])
  end
end
