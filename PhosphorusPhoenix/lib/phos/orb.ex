defmodule Phos.Orb do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uuid, :binary_id, autogenerate: true}
  schema "orb" do
    field :name, :string
    field :type, :string
    timestamps()
  end

  @doc false
  def changeset(echo, attrs) do
    echo
    |> cast(attrs, [:type, :name])
    |> validate_required([:type, :name ])
  end

  def recall(limit \\ 8) do
    Phos.Repo.all(Phos.Echo, limit: limit)
  end

  # def call(limit \\ 8, name) do
  #   Phos.Repo.all(Phos.Echo, limit: limit)
  # end
end
