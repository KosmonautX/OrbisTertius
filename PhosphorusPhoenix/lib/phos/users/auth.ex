defmodule Phos.Users.Auth do
  use Ecto.Schema

  import Ecto.Changeset

  alias Phos.Users.User

  schema "user_auths" do
    field :auth_id, :string
    field :auth_provider, :string

    belongs_to :user, User, references: :id, foreign_key: :user_id, type: Ecto.UUID

    timestamps()
  end

  @doc false
  def changeset(auth, attrs) do
    auth
    |> cast(attrs, [:auth_id, :auth_provider, :user_id]) #:auth_response
    |> cast_assoc(:user, with: &User.email_changeset/2)
    |> validate_required([:auth_id, :auth_provider])
  end
end
