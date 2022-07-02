defmodule Phos.Action.Location do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Orb, Orb_Location}

  @primary_key {:id, :integer, autogenerate: false}
  schema "locations" do
    many_to_many :orbs, Orb, join_through: Orb_Location, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:id])
  end
end
