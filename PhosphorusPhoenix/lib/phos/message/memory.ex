defmodule Phos.Message.Memory do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "memories" do
    field :media, :boolean, default: false
    field :message, :string
    belongs_to :user_source, Phos.Users.User, references: :id, type: Ecto.UUID
    belongs_to :orb_subject, Phos.Action.Orb, references: :id, type: Ecto.UUID

    has_many :reveries, Phos.Message.Reverie, references: :id, foreign_key: :memory_id, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(memory, attrs) do
    memory
    |> cast(attrs, [:id, :message, :media])
    |> validate_required([:message, :media])
  end
end
