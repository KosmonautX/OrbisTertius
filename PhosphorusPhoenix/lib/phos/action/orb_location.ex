defmodule Phos.Action.Orb_Location do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orbs_location" do
    field :hash, :string
    field :hashes, {:array, :string}
    field :radius, :integer

    timestamps()
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:hash, :hashes, :radius])
    # |> validate_required([:initiator, :acceptor])
  end
end
