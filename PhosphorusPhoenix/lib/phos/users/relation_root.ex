defmodule Phos.Users.RelationRoot do
  use Ecto.Schema
  use Fsmx.Struct, transitions: %{
    "requested" => ["ghosted", "completed", "blocked"],
    "ghosted" => "living",
    "living" => ["requested", "blocked"],
    "completed" => "living",
    "blocked" => "living"
  }

  import Ecto.Changeset, warn: false

  alias Phos.Users.{User,RelationBranch,RelationRoot}
  alias Phos.Repo

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "user_relations_root" do

    field :state, :string

    has_many :branches, RelationBranch, references: :id, foreign_key: :root_id, on_delete: :delete_all
    belongs_to :initiator, User, references: :id, type: Ecto.UUID
    belongs_to :acceptor, User, references: :id, type: Ecto.UUID
    belongs_to :last_memory, Phos.Message.Memory, references: :id, type: Ecto.UUID, on_replace: :update
    field :self_initiated, :boolean, virtual: true
    field :friend, :map, virtual: true

    timestamps()
  end

  def gen_branches_changeset(root, params) do
    root
    |> cast(params, [:acceptor_id, :initiator_id, :state])
    |> cast_assoc(:branches, with: &RelationBranch.changeset/2)
    |> validate_required([:initiator_id])
    |> foreign_key_constraint(:initiator_id)
    |> foreign_key_constraint(:acceptor_id)
  end


  def mutate_state_changeset(root, params) do
    root
    |> Fsmx.transition_changeset(params["state"], params)
  end

  def mutate_last_memory_changeset(root, params) do
    root
    |> cast(params, [:last_memory_id])
  end


  def transition_changeset(root = %{data: %RelationRoot{initiator_id: init, acceptor_id: acpt}}, _, "completed", params) do
    branches = [
      %{
        "completed_at" => NaiveDateTime.utc_now(),
        "friend_id" => init,
        "user_id" => acpt
      },
      %{
        "completed_at" => NaiveDateTime.utc_now(),
        "friend_id" => acpt,
        "user_id" => init
      }
    ]

    branched_params = %{state: params["state"], branches: branches}

    root.data
    |> Repo.preload(:branches)
    |> cast(branched_params , [:state])
    |> cast_assoc(:branches, with: &RelationBranch.complete_friendship_changeset/2)
    |> validate_required([:state])
  end

  def transition_changeset(root = %{data: %RelationRoot{initiator_id: init, acceptor_id: acpt}}, _, "blocked", params) do
    now = NaiveDateTime.utc_now()
    branches = [
      %{
        "blocked_at" => now,
        "friend_id" => init,
        "user_id" => acpt
      },
      %{
        "blocked_at" => now,
        "friend_id" => acpt,
        "user_id" => init
      }
    ]

    branched_params = %{state: params["state"], branches: branches}

    root.data
    |> Repo.preload(:branches)
    |> cast(branched_params , [:state])
    |> cast_assoc(:branches, with: &RelationBranch.complete_blockship_changeset/2)
    |> validate_required([:state])
  end
end
