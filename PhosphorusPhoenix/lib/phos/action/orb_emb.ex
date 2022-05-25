defmodule Phos.Action.Orb_Emb do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Orb_Initiator, Orb_Location, Orb_Emb_Payload, Orb_Orb_Location}

  @primary_key {:orb_id, :binary_id, autogenerate: true}
  schema "orbs_emb" do
    field :active, :boolean, default: false
    field :extinguish, :naive_datetime
    field :media, :boolean, default: false
    field :title, :string

    many_to_many :orbs_location, Orb_Location, join_through: Orb_Orb_Location, join_keys: [orb_id: :orb_id, location_id: :location_id]
    has_one :initiator, Orb_Initiator
    embeds_one :payload, Orb_Emb_Payload, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(%Phos.Action.Orb_Emb{} = orb, attrs) do
    orb
    |> cast(attrs, [:title, :active, :media, :extinguish])
    # |> cast_embed(:location)
    |> validate_required([:title, :active, :media, :extinguish])
  end

  # attrs = %Phos.Action.Orb_Emb{} |> Ecto.Changeset.cast(%{orbs_location: %{location_id: "88652634e7fffff"}, payload: %{image: "S3 path", time: 1653533097, tip: "starbuck", info: "more more text"}, title: "rand"}, [:title]) |> Ecto.Changeset.cast_assoc(:orbs_location) |> Ecto.Changeset.cast_embed(:payload)
  # attrs = %Phos.Action.Orb_Emb{} |> Ecto.Changeset.cast(%{payload: %{image: "S3 path", time: 1653533097, tip: "starbuck", info: "more more text"}, title: "rand"}, [:title]) |> Ecto.Changeset.cast_embed(:payload)
  # attrs = %Phos.Action.Orb_Emb{} |> Ecto.Changeset.cast(%{orbs_location: %{location_id: "88652634e7fffff"}, title: "rand"}, [:title]) |> Ecto.Changeset.cast_assoc(:orbs_location)
end
