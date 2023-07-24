defmodule Phos.Users.RelationBranch do
  use Ecto.Schema

  import Ecto.Changeset, warn: false

  alias Phos.Users.{RelationRoot, User}

  @primary_key false
  schema "user_relations_branches" do

    belongs_to :user, User, references: :id, type: Ecto.UUID, primary_key: true
    belongs_to :friend, User, references: :id, type: Ecto.UUID, primary_key: true
    belongs_to :root , RelationRoot, references: :id, type: Ecto.UUID, on_replace: :update

    field :completed_at, :naive_datetime
    field :blocked_at, :naive_datetime
    field :last_read_at, :naive_datetime
  end

  def changeset(relation, attrs) do
    relation
    |> cast(attrs, [:user_id, :friend_id, :root_id])
    |> validate_required([:user_id, :friend_id])
    #|> unique_constraint([:user_id, :friend_id], name: :mutual_relation_index, message: "already exists")
    |> unique_constraint([:user_id, :friend_id], name: :user_relations_branches_pkey, message: "already exists")
  end

  def complete_friendship_changeset(relation, attrs) do
    relation
    |> cast(attrs, [:completed_at])
    |> Map.put(:repo_opts, [on_conflict: {:replace, [:completed_at]}, conflict_target: [:user_id, :friend_id]])
  end

  def complete_blockship_changeset(relation, attrs) do
    relation
    |> cast(attrs, [:blocked_at])
    |> Map.put(:repo_opts, [on_conflict: {:replace, [:blocked_at]}, conflict_target: [:user_id, :friend_id]])
  end
end
