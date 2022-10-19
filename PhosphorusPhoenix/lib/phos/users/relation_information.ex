defmodule Phos.Users.RelationInformation do
  use Ecto.Schema
  use Fsmx.Struct, transitions: %{
    "requested" => ["hold", "accepted"],
    "hold" => "waited",
    "waited" => ["requested", "rejected"],
    "accepted" => "completed",
    "rejected" => "completed",
  }

  import Ecto.Changeset, warn: false

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "user_relation_informations" do
    field :requester_id, Ecto.UUID
    field :state, :string

    timestamps()
  end

  def changeset(information, params) do
    information
    |> cast(params, [:requester_id, :state])
    |> validate_required([:requester_id])
  end
end
