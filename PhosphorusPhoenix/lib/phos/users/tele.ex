defmodule Phos.Users.Tele do
  use Ecto.Schema
  # import Ecto.Changeset
  # alias Phos.Users.{User}

  @primary_key false
  schema "tele" do
    # belongs_to :users, User, references: :fyr_id, foreign_key: :id, type: :string

  end

  # def changeset(%Phos.Users.Fyr{} = fyr, attrs) do
  #   fyr
  #   |> cast(attrs, [:id])
  # end
end
