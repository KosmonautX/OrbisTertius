defmodule Phos.Action.Orb_Payload do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :when, :string
    field :where, :string
    field :info, :string
    field :tip, :string
    field :inner_title, :string

    embeds_one :ext_link, Extlink do
      field :name, :string, primary_key: true
      field :url, :string
      field :referral, :string
    end
  end

  @doc false
  def changeset(orb, attrs) do
    orb
    |> cast(attrs, [:when, :where, :info, :tip, :inner_title])
  end

  def admin_changeset(orb, attrs) do
    orb
    |> cast(attrs, [:when, :where, :info, :tip, :inner_title])
    |> cast_embed(:ext_link, with: &extlink_changeset/2)
  end

  def extlink_changeset(orb, attrs) do
    orb
    |> cast(attrs, [:name, :url, :referral])
  end
end
