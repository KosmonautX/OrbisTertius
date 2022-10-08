defmodule Phos.Action.Orb do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Location,Orb, Orb_Payload, Orb_Location}
  alias Phos.Users.{User}

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "orbs" do
    field :active, :boolean, default: false
    field :extinguish, :naive_datetime
    field :media, :boolean, default: false
    field :title, :string
    field :source, Ecto.Enum, values: [:web, :tele, :api]
    field :central_geohash, :integer
    field :traits, {:array, :string}, default: []
    field :topic, :string, virtual: true
    field :comment_count, :integer, default: 0, virtual: true

    belongs_to :initiator, User, references: :id, type: Ecto.UUID
    #belongs_to :users, User, references: :id, foreign_key: :acceptor, type: Ecto.UUID
    many_to_many :locations, Location, join_through: Orb_Location, on_replace: :delete, on_delete: :delete_all#, join_keys: [id: :id, location_id: :location_id]
    embeds_one :payload, Orb_Payload, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(%Orb{} = orb, attrs) do
    orb
      |> cast(attrs, [:id, :title, :active, :media, :extinguish, :source, :central_geohash, :initiator_id, :traits])
      |> cast_embed(:payload)
      |> validate_required([:title, :active, :media, :extinguish])
      # |> validate_media()
  end

  @doc """
  Orb changeset for editing orb.

  Editing orb does not need fields like geolocation.
  """
  def changeset_edit(user, attrs) do
    user
    |> cast(attrs, [:title, :active, :media, :extinguish, :traits])
    |> cast_embed(:payload)
  end

  def territorial_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:id, :active])
    |> cast_assoc(:locations)
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  def changeset_update_locations(%Orb{} = orb, locations) do
    orb
    |> cast(%{}, [:id, :title, :active, :media, :extinguish, :source, :central_geohash, :initiator_id, :traits])
    |> put_assoc(:locations, locations)
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
