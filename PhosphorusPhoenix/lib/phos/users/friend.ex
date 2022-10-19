defmodule Phos.Users.Friend do
  use Ecto.Schema

  import Ecto.Changeset

  alias Phos.Users.{User, Relation}

  @primary_key false
  schema "user_friends" do
    belongs_to :user, User, references: :id, type: Ecto.UUID, primary_key: true
    belongs_to :friend, User, references: :id, type: Ecto.UUID, primary_key: true
    belongs_to :relation, Relation, references: :id, type: Ecto.UUID, primary_key: true
  end

  def changeset(friend, attrs) do
    friend
    |> cast(attrs, [:user_id, :friend_id, :relation_id])
    |> validate_required([:user_id, :friend_id, :relation_id])
  end
end
