defmodule Phos.Action.Location do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Orb, Orb_Location}

  @primary_key {:id, :integer, autogenerate: false}
  schema "locations" do
    many_to_many :orbs, Orb, join_through: Orb_Location, on_replace: :delete
    has_many :memories, Phos.Message.Memory, references: :id, foreign_key: :loc_subject_id
    belongs_to :last_memory, Phos.Message.Memory, references: :id, type: Ecto.UUID, on_replace: :update

    timestamps()
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:id, :last_memory_id])
    |> Map.put(:repo_opts, [on_conflict: :nothing, conflict_target: :id])
  end

  def mutate_last_memory_changeset(root, params) do
    root
    |> cast(params, [:last_memory_id])
  end
end
