defmodule Phos.Repo.Migrations.UpdateRelationBranches do
  use Ecto.Migration

  def change do
    alter table(:user_relations_branches) do
      modify :root_id, references(:user_relations_root, column: :id, type: :uuid, on_delete: :delete_all),
        from: references(:user_relations_root, column: :id, type: :uuid)
    end
  end


end
