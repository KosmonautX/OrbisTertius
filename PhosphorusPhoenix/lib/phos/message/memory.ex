defmodule Phos.Message.Memory do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Message.Reverie

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]
  schema "memories" do
    field :media, :boolean, default: false
    field :message, :string
    field :action_path, :string, default: nil
    belongs_to :user_source, Phos.Users.User, references: :id, type: Ecto.UUID
    belongs_to :orb_subject, Phos.Action.Orb, references: :id, type: Ecto.UUID
    belongs_to :rel_subject, Phos.Users.RelationRoot, references: :id, type: Ecto.UUID
    belongs_to :com_subject, Phos.Comments.Comment, references: :id, type: Ecto.UUID
    belongs_to :loc_subject, Phos.Action.Location, references: :id, type: :integer
    has_one :last_rel_memory, Phos.Users.RelationRoot, foreign_key: :last_memory_id

    field :cluster_subject_id, :binary_id, default: nil, virtual: true

    has_many :reveries, Reverie, references: :id, foreign_key: :memory_id, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(memory, attrs) do
    memory
    |> cast(attrs, [:id,:user_source_id, :orb_subject_id, :com_subject_id, :rel_subject_id, :loc_subject_id, :message, :media])
    |> cast_assoc(:loc_subject)
    |> validate_required([:message, :media])
    |> foreign_key_constraint(:user_source_id)
  end

  def gen_changeset(memory, attrs) do
    memory
    |> cast(attrs, [:id, :user_source_id, :orb_subject_id, :rel_subject_id, :message, :media])
    |> validate_required([:id, :user_source_id, :message, :media, :rel_subject_id])
    |> foreign_key_constraint(:user_source_id)
    |> foreign_key_constraint(:rel_subject_id)
  end

  def gen_reveries_changeset(memory, attrs) do
    memory
    |> cast(attrs, [:id, :user_source_id, :orb_subject_id, :rel_subject_id, :media, :message])
    |> cast_assoc(:reveries, with: &Reverie.gen_changeset/2)
    |> validate_required([:id, :user_source_id])
    |> foreign_key_constraint(:user_source_id)
    |> foreign_key_constraint(:rel_subject_id)
  end
end
