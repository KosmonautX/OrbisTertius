defmodule Phos.Message.Reverie do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "reveries" do
    field :read, :utc_datetime
    belongs_to :user_destination, Phos.Users.User, references: :id, type: Ecto.UUID
    belongs_to :memory, Phos.Message.Memory, references: :id, type: Ecto.UUID

    timestamps()
  end

  @doc false
  def changeset(reverie, attrs) do
    reverie
    |> cast(attrs, [:read, :user_destination_id, :memory_id])
    |> validate_required([:user_destination_id, :memory_id])
  end

  def update_changeset(reverie, attrs) do
    reverie
    |> cast(attrs, [:read])
  end
end
