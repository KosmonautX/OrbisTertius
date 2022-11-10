defmodule Phos.Repo.Migrations.UpdatePrivateprofileRelationBranch do
  use Ecto.Migration

  def change do
    alter table(:user_relations_branches) do
      modify :root_id, references(:user_relations_root, column: :id, type: :uuid, on_delete: :delete_all),
        from: references(:user_relations_root, column: :id, type: :uuid)
    end

    alter table(:private_profile) do
      modify :user_id, references(:users, column: :id, type: :uuid, on_delete: :delete_all),
        from: :uuid
    end

    alter table(:users) do
      add :integrations, :jsonb
    end

  end



end
