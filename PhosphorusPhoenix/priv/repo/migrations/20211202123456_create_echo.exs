defmodule Chat.Repo.Migrations.CreateEcho do
  use Ecto.Migration

  def change do
    create table(:echo) do

      add :source_archetype, :string
      add :source, :string
      add :destination_archetype, :string
      add :destination, :string
      add :message, :string
      add :subject_archetype, :string
      add :subject, :string

      timestamps()
    end

    create index(:echo, [:source, :source_archetype])
    create index(:echo, [:destination, :destination_archetype])

  end
end
