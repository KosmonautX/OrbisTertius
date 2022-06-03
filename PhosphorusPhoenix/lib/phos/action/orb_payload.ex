defmodule Phos.Action.Orb_Payload do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :when, :string
    field :where, :string
    field :info, :string
    field :tip, :string

    timestamps()
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:when, :where, :info, :tip])
  end
end
