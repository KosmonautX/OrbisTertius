defmodule Phos.Action.Orb_Payload do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :when, :string
    field :where, :string
    field :info, :string
    field :tip, :string
    field :inner_title, :string
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:when, :where, :info, :tip, :inner_title])
  end
end
