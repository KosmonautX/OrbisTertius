defmodule Phos.Repo.Migrations.AlterTableUserModifyUserEmail do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :email, :citext, null: true, from: {:citext, null: false}
    end
  end
end
