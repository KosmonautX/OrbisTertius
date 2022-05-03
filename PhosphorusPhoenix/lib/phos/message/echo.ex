defmodule Phos.Message.Echo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "echo" do
    field :source, :string
    field :source_archetype, :string
    field :destination, :string
    field :destination_archetype, :string
    field :message, :string
    field :subject, :string
    field :subject_archetype, :string

    timestamps()
  end

  @doc false

  def changeset(echo, attrs) do
    echo
    |> cast(attrs, [:source_archetype, :source, :destination_archetype, :destination, :message, :subject_archetype, :subject])
    |> validate_required([:message, :source, :destination, :source_archetype, :destination_archetype])
    |> validate_length(:source_archetype, is: 3)
    |> validate_length(:destination_archetype, is: 3)
  end
end
