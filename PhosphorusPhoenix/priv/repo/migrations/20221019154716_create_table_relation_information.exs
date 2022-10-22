defmodule Phos.Repo.Migrations.CreateTableRelationInformation do
  use Ecto.Migration

  def change do

    create table(:user_relations_root, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :initiator_id, references(:users, column: :id, type: :uuid)
      add :acceptor_id, references(:users, column: :id, type: :uuid)
      add :state, :string, default: "requested"

      timestamps()
    end
  end
end
