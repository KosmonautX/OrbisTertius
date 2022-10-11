defmodule Phos.Repo.Migrations.CreateTableFriends do
  use Ecto.Migration

  def change do
    create index(:orbs, :initiator_id)
    create index(:comments, :initiator_id)
    create index(:comments, :parent_id)

  end
end
