defmodule Phos.Users.Integrations do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :fcm_token, :string
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, __MODULE__.__schema__(:fields))
  end

end
