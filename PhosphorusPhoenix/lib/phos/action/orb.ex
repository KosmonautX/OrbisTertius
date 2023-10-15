defmodule Phos.Action.Orb do

  @moduledoc """

  Schema for Orbs the primitive for posting

  """
  use Ecto.Schema

  import Ecto.Changeset

  alias EctoLtree.LabelTree, as: Ltree
  alias Phos.Action.{Location, Orb, Orb_Payload, Orb_Location, Blorb, Permission}
  alias Phos.Users.User
  alias Phos.Comments.Comment

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
    field :number_of_repost, :integer, default: 0, virtual: true
    field :path, Ltree
    field :distance, :integer, default: 0, virtual: true

    field :embedding, Pgvector.Ecto.Vector

    belongs_to :initiator, User, references: :id, type: Ecto.UUID
    belongs_to :parent, __MODULE__, references: :id, type: Ecto.UUID
    #belongs_to :users, User, references: :id, foreign_key: :acceptor, type: Ecto.UUID

    has_many :members, Permission, references: :id, foreign_key: :orb_id
    has_many :locs, Orb_Location, references: :id, foreign_key: :orb_id
    has_many :comments, Comment, references: :id, foreign_key: :orb_id
    has_many :blorbs, Blorb, references: :id, foreign_key: :orb_id, on_replace: :delete

    many_to_many :locations, Location, join_through: Orb_Location, on_replace: :delete, on_delete: :delete_all#, join_keys: [id: :id, location_id: :location_id]
    embeds_one :payload, Orb_Payload, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(%Orb{} = orb, attrs) do
    orb
    |> cast(attrs, [:id, :title, :active, :media, :extinguish, :source, :central_geohash, :initiator_id, :traits, :path, :parent_id, :embedding, :inserted_at])
    |> cast_embed(:payload)
    |> cast_assoc(:locations)
    |> cast_assoc(:blorbs)
    |> cast_assoc(:members, with: &Permission.orb_changeset/2)
    |> validate_required([:id, :title, :active, :media, :extinguish, :initiator_id])
    |> set_blorb_initiators()
    |> validate_exclude_subset(:traits, ~w(admin pin personal exile mirage))
    #|> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  def set_blorb_initiators(%{changes: %{initiator_id: init_id, blorbs: blorb} = orb_changes} = orb_changeset) do
    %{orb_changeset| changes: %{orb_changes | blorbs: Enum.map(blorb,
         fn %{changes: blorb_changes} = blorb_changeset ->
           %{blorb_changeset | changes: Map.put(blorb_changes, :initiator_id, init_id)} end)}}
  end
  def set_blorb_initiators(changeset), do: changeset

  def set_blorb_initiators(%{changes: %{blorbs: blorb} = orb_changes} = orb_changeset, %{initiator: init_id}) do
    %{orb_changeset| changes: %{orb_changes | blorbs: Enum.map(blorb,
         fn %{changes: blorb_changes} = blorb_changeset ->
           %{blorb_changeset | changes: Map.put(blorb_changes, :initiator_id, init_id)} end)}}
  end
  def set_blorb_initiators(changeset, _attrs), do: changeset

  # @doc """
  # Set same initiator as orb for blorbs upon creation due to shared provenance
  # """
  # def set_initiator(%Blorb{} = blorb, %Orb{} = orb) do
  #   IO.inspect blorb
  #   IO.inspect orb
  #   %{blorb | initiator_id: orb.initiator_id}
  # end

  @doc """
  Orb changeset for editing orb.

  Editing orb does not need fields like geolocation.
  """
  def update_changeset(%Orb{} = orb, attrs) do
    orb
    |> cast(attrs, [:title, :active, :media, :traits, :embedding])
    |> cast_embed(:payload)
    |> cast_assoc(:blorbs, with: &Blorb.mutate_changeset/2)
    |> validate_exclude_subset(:traits, ~w(admin personal pin exile mirage), message: "unnatural traits")
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  def personal_changeset(%Orb{} = orb, attrs) do
    orb
    |> Map.put(:userbound, true)
    |> cast(attrs, [:id, :active, :userbound, :initiator_id, :traits, :title])
    |> cast_embed(:payload)
    |> validate_required([:id, :active, :userbound, :initiator_id])
    |> validate_exclude_subset(:traits, ~w(admin pin exile mirage))
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
    |> cast(attrs, [:id, :title, :active, :media, :extinguish, :source, :central_geohash, :initiator_id, :traits, :embedding])
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

  def reorb_changeset(user_id, orb, %Comment{} = comment) do
    reorb_changeset(user_id, orb, nil)
    |> put_assoc(:reposted_comment, comment)
  end
  def reorb_changeset(user_id, orb, nil) do
    id = Ecto.UUID.generate()
    payload = case orb.payload do
      nil -> %{}
      _ -> Map.from_struct(orb.payload)
    end
    path = case orb.path do
      %{labels: []} -> Phos.Utility.Encoder.encode_lpath(id, orb.id)
      %{labels: labels} -> Phos.Utility.Encoder.encode_lpath(id, labels)
      _ -> Phos.Utility.Encoder.encode_lpath(id, orb.id)
    end
    attrs =
      Map.from_struct(orb)
      |> Map.take(~W(active central_geohash extinguish media title topic userbound)a)
      |> Map.merge(%{
        id: id,
        path: path,
        initiator_id: user_id,
        traits: ["reorb" | Map.get(orb, :traits, [])],
        payload: payload
      })

    changeset(%__MODULE__{}, attrs)
    |> put_change(:parent_id, orb.id)
  end

end
