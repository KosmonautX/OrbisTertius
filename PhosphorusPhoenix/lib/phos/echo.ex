defmodule Phos.Echo do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "echo" do
    field :source_archetype, :string
    field :source, :string
    field :destination_archetype, :string
    field :destination, :string
    field :message, :string
    field :subject_archetype, :string
    field :subject, :string

    timestamps()
  end

  @doc false
  def changeset(echo, attrs) do
    echo
    |> cast(attrs, [:source_archetype, :source, :destination_archetype, :destination, :message, :subject_archetype, :subject])
    |> validate_required([:message, :source, :destination, :source_archetype, :destination_archetype])
    |> validate_length([:source_archetype, :destination_archetype], is: 3)
  end

  def recall(limit \\ 8) do
    Phos.Repo.all(Phos.Echo, limit: limit)
  end

  def ur_call(archetype, id) do
    query = Phos.Echo
    |> where([e], e.source == ^id and e.source_archetype == ^archetype )
    |> or_where([e], e.destination == ^id and e.destination_archetype == ^archetype)
    |> order_by([e], desc: e.inserted_at)
    Phos.Repo.all(query, limit: 8)
  end

  def usr_call(id) do
    ur_call("USR", id)
  end
end
