defmodule Phos.MessageFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Phos.Message` context.
  """

  @doc """
  Generate a echo.
  """
  def echo_fixture(attrs \\ %{}) do
    {:ok, echo} =
      attrs
      |> Enum.into(%{
        destination: "some destination",
        destination_archetype: "USR",
        message: "some message",
        source: "some source",
        source_archetype: "USR",
        subject: "some subject",
        subject_archetype: "USR"
      })
      |> Phos.Message.create_echo()

    echo
  end
end
