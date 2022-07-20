defmodule Phos.ActionFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Phos.Action` context.
  """

  import Phos.UsersFixtures
  @doc """
  Generate a orb.
  """
  def orb_fixture(attrs \\ %{}) do
    %{id: user_id} = user = user_fixture()
    {:ok, orb} =
      attrs
      |> Enum.into(%{"id" => Ecto.UUID.generate(), "geolocation" => [623276216934563839] ,"title" => "some title", "active" => true, "extinguish" => %{day: 21, hour: 7, minute: 22, month: 5, year: 2022}, "source" => :web, "initiator_id" => user_id, "location" => :home, "radius" => 8, "payload" => %{"info" => "some info", "tip" => "some tip", "when" => "some when", "where" => "some where"}})
      |> Phos.Action.create_orb()

      orb |> Phos.Repo.preload([:locations,:initiator])
  end

  def orb_fixture_no_location(attrs \\ %{}) do
    %{id: user_id} = user = user_fixture()
    {:ok, orb} =
      attrs
      |> Enum.into(%{
        "id" => Ecto.UUID.generate(),
        "active" => true,
        "extinguish" => ~N[2022-05-20 12:12:00],
        "media" => true,
        "title" => "some title",
        "initiator_id" => user_id
      })
      |> Phos.Action.create_orb()

      orb |> Phos.Repo.preload([:locations,:initiator])
  end
end
