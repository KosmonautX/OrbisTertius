defmodule Phos.Action.Orb do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orbs" do
    field :active, :boolean, default: false
    field :extinguish, :naive_datetime
    field :media, :boolean, default: false
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:title, :active, :media, :extinguish])
    |> validate_required([:title, :active, :media, :extinguish])
  end
end
