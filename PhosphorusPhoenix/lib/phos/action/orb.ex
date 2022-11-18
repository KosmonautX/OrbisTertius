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
    field :source, Ecto.Enum, values: [:web, :tele, :api], default: :api
    field :central_geohash, :integer
    field :traits, {:array, :string}, default: []
    field :userbound, :boolean, default: false
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
    |> cast_assoc(:locations)
    |> validate_required([:id, :title, :active, :media, :extinguish, :initiator_id])
    |> validate_exclude_subset(:traits, ~w(admin pin personal))
    #|> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  @doc """
  Orb changeset for editing orb.

  Editing orb does not need fields like geolocation.
  """
  def update_changeset(%Orb{} = orb, attrs) do
    orb
    |> cast(attrs, [:title, :active, :media, :traits])
    |> cast_embed(:payload)
    |> validate_required([:active, :title])
    |> validate_exclude_subset(:traits, ~w(admin personal pin), message: "unnatural traits")
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  def personal_changeset(%Orb{} = orb, attrs) do
    orb
    |> Map.put(:userbound, true)
    |> cast(attrs, [:id, :active, :userbound, :initiator_id, :traits, :title])
    |> cast_embed(:payload)
    |> validate_required([:id, :active, :userbound, :initiator_id])
    |> validate_exclude_subset(:traits, ~w(admin pin))
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  def territorial_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:id, :active, :userbound, :initiator_id])
    |> cast_assoc(:locations)
    |> validate_required([:id, :active, :userbound, :initiator_id])
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  def admin_changeset(%Orb{} = orb, attrs) do
    orb
    |> cast(attrs, [:id, :title, :active, :media, :extinguish, :source, :central_geohash, :initiator_id, :traits])
    |> cast_embed(:payload, with: &Orb_Payload.admin_changeset/2)
    |> cast_assoc(:locations)
    |> validate_required([:id, :title, :active, :media, :initiator_id])
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  def validate_media(changeset) do
    image = get_field(changeset, :image)

    if Enum.empty?(image) do
      add_error(changeset, :image, "must insert media")
    else
      changeset
    end
  end


  defp validate_exclude_subset(changeset, field, data, opts \\ []) do
    validate_change changeset, field, {:superset, data}, fn _, value ->
      element_type =
        case Map.fetch!(changeset.types, field) do
          {:array, element_type} ->
            element_type
          type ->
            {:array, element_type} = Ecto.Type.type(type)
            element_type
        end

      Enum.map(data, &Ecto.Type.include?(element_type, &1, value))
      |> Enum.member?(true)
      |> case do
        true -> [{field, {Keyword.get(opts, :message, "has an invalid entry"), [validation: :superset, enum: data]}}]
        _ -> []
      end
    end
  end
end
