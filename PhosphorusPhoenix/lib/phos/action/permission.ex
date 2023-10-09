defmodule Phos.Action.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "orb_permissions" do
    field :state, Ecto.Enum, values: [invited: 0, collab: 1, mention: 2, collab_invite: 3]
    belongs_to :orb, Orb, type: Ecto.UUID, references: :id, foreign_key: :orb_id, primary_key: true
    belongs_to :user, User, references: :id, type: Ecto.UUID

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = permission, attrs) do
    permission
    |> cast(attrs, [:state, :orb_id, :user_id])
    |> validate_required([:state])
  end
end
