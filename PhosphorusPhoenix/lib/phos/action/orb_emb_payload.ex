defmodule Phos.Action.Orb_Emb_Payload do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :image, :string
    field :time, :integer
    field :tip, :string
    field :info, :string

    timestamps()
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:image, :time, :tip, :info])
    # |> validate_required([:initiator, :acceptor])
  end
end
