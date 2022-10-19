defmodule Phos.Users.Relation do
  use Ecto.Schema

  import Ecto.Changeset, warn: false

  alias Phos.Users.{RelationInformation, User}

  @primary_key false
  schema "user_relations" do
    belongs_to :user, User, references: :id, type: Ecto.UUID, primary_key: true
    belongs_to :friend, User, references: :id, type: Ecto.UUID, primary_key: true
    belongs_to :information, RelationInformation, references: :id, type: Ecto.UUID

    field :completed_at, :naive_datetime
  end

  def changeset(relation, attrs) do
    relation
    |> cast(attrs, [:user_id, :friend_id, :information_id, :completed_at])
  end
end
