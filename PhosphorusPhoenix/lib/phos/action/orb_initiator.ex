defmodule Phos.Action.Orb_Initiator do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orbs_initiator" do
    field :user_id, :string

    timestamps()
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:initiator, :acceptor])
    # |> validate_required([:initiator, :acceptor])
  end
end
