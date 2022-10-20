defmodule Phos.Repo.Migrations.CreateTableRelationInformation do
  use Ecto.Migration

  def change do

    create table(:user_relation_informations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :requester_id, :uuid, null: false
      add :state, :string, default: "requested"

      timestamps()
    end
  end
end
