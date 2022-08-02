defmodule Phos.Users.Email do
  import Swoosh.Email

  def welcome(%Phos.Users.User{email: email, username: username} = _user), do: welcome(username, email)
  def welcome(display_name, email) do
    new()
    |> to({ display_name, email })
    |> from({ "ScratchBac", "admin@scratchbac.com" })
    |> subject("Hello, #{display_name}")
    |> html_body("<h1>Body Email</h1>")
    |> text_body("Welcome to ScratchBac")
  end
end
