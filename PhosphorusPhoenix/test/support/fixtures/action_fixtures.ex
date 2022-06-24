defmodule Phos.ActionFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Phos.Action` context.
  """

  @doc """
  Generate a orb.
  """
  def orb_fixture(attrs \\ %{}) do
    {:ok, orb} =
      %{id: Ecto.UUID.generate, title: "some title", active: true, extinguish: %{day: 21, hour: 7, minute: 22, month: 5, year: 2022}, source: :web, initiator: "", location: :home, radius: 10, geolocation: [623276216934563839], central_geohash: 623276216934563839, payload: %{info: "some info",tip: "some tip", when: "some when", where: "some where"}}
      |> Phos.Action.create_orb()

      orb
    # orb |> Phos.Repo.preload(:locations) |> Phos.Repo.preload(:users)
  end

  def orb_fixture_no_location(attrs \\ %{}) do
    {:ok, orb} =
      attrs
      |> Enum.into(%{
        "id" => Ecto.UUID.generate(),
        "active" => true,
        "extinguish" => ~N[2022-05-20 12:12:00],
        "media" => true,
        "title" => "some title",
      })
      |> Phos.Action.create_orb()

      orb
    # orb |> Phos.Repo.preload(:locations) |> Phos.Repo.preload(:users)
  end
end
