defmodule Phos.Action.Orb do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Location, Orb_Payload, Orb_Location}
  alias Phos.Users.{User}

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "orbs" do
    field :active, :boolean, default: false
    field :extinguish, :naive_datetime
    field :media, :boolean, default: false
    field :title, :string
    field :source, Ecto.Enum, values: [:web, :tele, :flutter]
    field :central_geohash, :integer
    field :traits, {:array, :string}
    field :topic, :string, virtual: true

    belongs_to :users, User, references: :id, foreign_key: :initiator, type: Ecto.UUID
    #belongs_to :users, User, references: :id, foreign_key: :acceptor, type: Ecto.UUID
    many_to_many :locations, Location, join_through: Orb_Location, on_delete: :delete_all#, join_keys: [id: :id, location_id: :location_id]
    embeds_one :payload, Orb_Payload, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(%Phos.Action.Orb{} = orb, attrs) do
    orb
    |> cast(attrs, [:id, :title, :active, :media, :extinguish, :source, :central_geohash, :initiator, :traits])
    |> cast_assoc(:locations)
    |> assoc_constraint(:users)
    |> cast_embed(:payload)
    |> validate_required([:title, :active, :media, :extinguish])
    # |> validate_media()
  end

  def validate_media(changeset) do
    image = get_field(changeset, :image)

    if Enum.empty?(image) do
      changeset = add_error(changeset, :image, "must insert media")
    else
      changeset
    end

  end
end
