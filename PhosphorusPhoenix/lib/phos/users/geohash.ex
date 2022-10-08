defmodule Phos.Users.Geolocation do
  use Ecto.Schema
  import Ecto.Changeset
  @derive Jason.Encoder

  @primary_key{:id, :string, autogenerate: false}
  embedded_schema do
    field :location_description, :string
    field :geohash, :integer
    field :chronolock, :integer #, autogenerate: {__MODULE__, :set_time, []}
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs |> Map.put_new_lazy("chronolock", &__MODULE__.timelock/0), [:id, :location_description, :geohash, :chronolock])
    |> validate_required([:id, :geohash])
    |> validate_inclusion(:id, ["home", "work", "play"])
    |> Map.put(:repo_opts, [on_conflict: {:replace_all_except, [:id]}, conflict_target: :id])
  end

  def timelock, do: DateTime.utc_now() |> DateTime.to_unix()
 end
