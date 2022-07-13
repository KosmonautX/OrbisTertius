defmodule Phos.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias EctoLtree.LabelTree, as: Ltree
  alias Phos.Comments.{Comment}
  alias Phos.Action.{Orb}
  alias Phos.Users.{User}

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "comments" do
    field :body, :string
    field :path, Ltree
    field :active, :boolean, default: true
    field :child_count, :integer, default: 0, virtual: true

    belongs_to :orb, Orb, references: :id, type: Ecto.UUID
    belongs_to :initiator, User, references: :id, type: Ecto.UUID
    belongs_to :parent, Comment, references: :id, type: Ecto.UUID

    timestamps()
  end

  @doc false
  def changeset(%Comment{} = comment, attrs) do
    comment
      |> cast(attrs, [:id, :body, :path, :active, :orb_id, :initiator_id, :parent_id])
      |> validate_required([:id, :body, :path, :orb_id, :initiator_id])
  end

  def changeset_edit(comment, attrs) do
    comment
    |> cast(attrs, [:id, :body, :path, :active])
  end

end
