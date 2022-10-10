defmodule Phos.Users.Relation do
  use Ecto.Schema
  use Fsmx.Struct, transitions: %{
    "REQUESTED" => ["HOLD", "ACCEPTED"],
    "HOLD" => "GHOSTED",
    "GHOSTED" => ["REQUESTED", "REJECTED"],
    "ACCEPTED" => "COMPLETED",
    "REJECTED" => "REQUESTED",
  }

  import Ecto.Changeset

  alias Phos.Users.User

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @derive {Jason.Encoder, only: [:requester_id, :acceptor_id, :requested_at, :accepted_at, :state]}
  schema "user_relations" do
    belongs_to :requester, User, references: :id, type: Ecto.UUID
    belongs_to :acceptor, User, references: :id, type: Ecto.UUID

    field :state, :string, default: "REQUESTED"
    field :requested_at, :naive_datetime
    field :accepted_at, :naive_datetime
  end

  def changeset(relation, attrs) do
    relation
    |> cast(attrs, [:requester_id, :acceptor_id, :state, :accepted_at])
    |> validate_required([:requester_id, :acceptor_id])
    |> validate_users()
    |> default_fields()
  end

  defp default_fields(changeset) do
    time = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    case get_field(changeset, :requested_at) do
      nil -> put_change(changeset, :requested_at, time)
      _ -> changeset
    end
  end

  defp validate_users(changeset) do
    requester = get_field(changeset, :requester_id)
    acceptor = get_field(changeset, :acceptor_id)

    case String.equivalent?(requester, acceptor) do
      true -> add_error(changeset, :user, "Cannot add yourself to be a friend")
      _ -> changeset
    end
  end

  @doc false
  def transition_changeset(changeset, _current_state, state, _params) when state in ["ACCEPTED"] do
    time = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    changeset
    |> changeset(%{accepted_at: time})
    |> validate_required([:accepted_at])
  end
end
