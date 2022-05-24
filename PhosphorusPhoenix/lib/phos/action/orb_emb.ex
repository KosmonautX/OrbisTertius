defmodule Phos.Action.Orb_Emb do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Orb_Initiator, Orb_Location, Orb_Emb_Payload}

  schema "orbs_emb" do
    field :active, :boolean, default: false
    field :extinguish, :naive_datetime
    field :media, :boolean, default: false
    field :title, :string

    has_many :location, Orb_Location
    has_one :initator, Orb_Initiator
    # has_many :acceptor, Orb_Acceptor
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

  # attrs = %Phos.Action.Orb_Emb{} |> Ecto.Changeset.cast(%{location: %{hash: "88652634e7fffff", hashes: ["88652634e7fffff", "88652634e5fffff", "88652635dbfffff", "88652634adfffff", "88652634a9fffff", "88652634e3fffff", "88652634e1fffff"], radius: 8}], payload: %{image: "S3 path", time: 1653533097, tip: "starbuck", info: "more more text"}, title: "rand"}, [:title]) |> Ecto.Changeset.cast_embed(:payload)
end
