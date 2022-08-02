defmodule Phos.Repo.Migrations.AlterTableUserPublicprofile do
  use Ecto.Migration

  def change do
    drop_if_exists table("public_profile")

    alter table(:users) do
      add :public_profile, :jsonb
    end
  end
end
