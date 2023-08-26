defmodule Phos.Article.Content do
  use Ecto.Schema


  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "articles" do
    field :content, :string
    field :published_at, :naive_datetime

    embeds_one :additional_information, AdditionalInformation do
      field :orbs, {:array, :string}
    end

    timestamps()
  end
end
