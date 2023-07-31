defmodule Phos.UsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Phos.Users` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"
  def unique_user_name, do: "brucelee#{:erlang.phash2(:erlang.unique_integer(), 99_999_999)}"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      username: unique_user_name(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Phos.Users.register_user()

    user
  end

  def temp_tele_user_fixture(attrs \\ %{}) do
    options =
      %{
        "sub" => "#{Enum.random(1000000..3999999)}",
        "provider" => "telegram",
      }

    {:ok, user} = Phos.Users.from_auth(options)
    user
  end

  def user_pte_prof_fixture(attrs \\ %{}) do
    {:ok, user_created} = valid_user_attributes() |> Phos.Users.register_user()

    {:ok, user} =
      %Phos.Users.PrivateProfile{}
      |> Phos.Users.PrivateProfile.changeset(%{user_id: user_created.id})
      |> Ecto.Changeset.put_embed(:geolocation, [attrs])
      |> Phos.Repo.insert()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
