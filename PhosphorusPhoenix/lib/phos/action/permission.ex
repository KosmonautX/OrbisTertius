defmodule Phos.Action.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  use Fsmx.Struct, state_field: :action, transitions: %{
    :"*" => ["collab_invite", "mention"],
    :collab_invite => "collab",
    "mention" => "collab_invite",
    :mention => "collab_invite",
    :collab => "collab"
  }

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "orb_permissions" do
    field :action, Ecto.Enum, values: [collab_invite: 0, collab: 1, mention: 2]

    belongs_to :orb, Phos.Action.Orb, type: Ecto.UUID, references: :id, foreign_key: :orb_id
    belongs_to :member, Phos.Users.User, references: :id, type: Ecto.UUID
    belongs_to :token, Phos.Users.UserToken, references: :id

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = permission, attrs) do
    permission
    |> cast(attrs, [:action])
    |> cast_association(attrs, [:orb, :member, :token])
    |> validate_required([:action, :member, :orb])
    |> unique_constraint([:member_id, :orb_id])
  end

  def orb_changeset(%__MODULE__{} = permission, attrs) do
    permission
    |> Fsmx.transition_changeset(attrs["action"], attrs, [state_field: :action])
    |> cast(attrs, [:action, :member_id])
    |> validate_required([:action, :member_id])
    |> unique_constraint([:member_id, :orb_id])
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  def transition_changeset(%{data: permission}, _ , _, _attrs) do
    permission
  end

  defp cast_association(changeset, _attrs, []), do: changeset
  defp cast_association(changeset, attrs, [head | tail] = _fields) do
    case get_field(changeset, :"#{head}_id") do
      nil -> cast_association(changeset, attrs, head)
      _ -> changeset
    end
    |> cast_association(attrs, tail)
  end
  defp cast_association(changeset, attrs, key) do
    case Map.get(attrs, to_string(key)) do
      nil -> changeset
      %{id: _id} = data -> put_assoc(changeset, key, data)
    end
  end
end
