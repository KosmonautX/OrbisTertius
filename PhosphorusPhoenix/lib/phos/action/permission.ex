defmodule Phos.Action.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "orb_permissions" do
    field :action, Ecto.Enum, values: [invited: 0, collab: 1, mention: 2, collab_invite: 3]
    belongs_to :orb, Phos.Action.Orb, type: Ecto.UUID, references: :id, foreign_key: :orb_id
    belongs_to :user, Phos.Users.User, references: :id, type: Ecto.UUID
    belongs_to :token, Phos.Users.UserToken, references: :id

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = permission, attrs) do
    permission
    |> cast(attrs, [:action])
    |> cast_association(attrs, [:orb, :user, :token])
    |> validate_required([:action, :user, :orb])
    |> unique_constraint([:user_id, :orb_id])
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
