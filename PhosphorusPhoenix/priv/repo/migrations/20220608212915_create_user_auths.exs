defmodule Phos.Repo.Migrations.CreateUserAuths do
  use Ecto.Migration

  def change do
    create table(:user_auths) do
      add :auth_id, :string
      add :auth_provider, :string

      add :user_id, references(:users, column: :id, type: :uuid)

      timestamps()
    end

    create index(:user_auths, [:auth_id, :auth_provider])
  end
end
