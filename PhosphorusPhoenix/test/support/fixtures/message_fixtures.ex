defmodule Phos.MessageFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Phos.Message` context.
  """
  @doc """
  Generate a memory.
  """
  def memory_fixture(attrs \\ %{}) do
    {:ok, memory} =
      attrs
      |> Enum.into(%{
        media: true,
        message: "some message"
      })
      |> Phos.Message.create_memory()

    memory
  end

  @doc """
  Generate a reverie.
  """
  def reverie_fixture(attrs \\ %{}) do
    {:ok, reverie} =
      attrs
      |> Enum.into(%{
        read: ~U[2022-12-14 19:43:00Z]
      })
      |> Phos.Message.create_reverie()

    reverie
  end
end
