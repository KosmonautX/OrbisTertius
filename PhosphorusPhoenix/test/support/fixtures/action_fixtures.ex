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
      attrs
      |> Enum.into(%{
        active: true,
        extinguish: ~N[2022-05-20 12:12:00],
        media: true,
        title: "some title"
      })
      |> Phos.Action.create_orb()

    orb
  end

  @doc """
  Generate a orb.
  """
  def orb_fixture(attrs \\ %{}) do
    {:ok, orb} =
      attrs
      |> Enum.into(%{
        active: true,
        extinguish: ~N[2022-05-21 07:22:00],
        media: true,
        title: "some title"
      })
      |> Phos.Action.create_orb()

    orb
  end
end
