defmodule Phos.Repo.Migrations.AddArticleTable do
  use Ecto.Migration

  def change do
    create table(:articles, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :content, :string
      add :additional_information, :map
      add :published_at, :naive_datetime

      timestamps()
    end
  end
end
