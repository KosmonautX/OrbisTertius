defmodule Phos.User.Providers do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{User}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "providers" do
    field :google_id, :string
    field :apple_id, :string
    field :telegram_id, :string

    belongs_to :users, User

    timestamps()
  end

  @doc false
  def changeset(%Phos.User.Providers{} = providers, attrs) do
    providers
    |> cast(attrs, [:google_id, :apple_id, :telegram_id])

  end
end
