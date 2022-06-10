defmodule Phos.Repo.Migrations.AddEmailToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :email, :string
      add :password_hash, :string
    end
    create index(:users, [:email])
  end
end
