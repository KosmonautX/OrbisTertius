defmodule Phos.MessageFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Phos.Message` context.
  """
  @doc """
  Generate a memory.
  """
  def memory_fixture(attrs \\ %{}) do
    %{id: user_id} = user = Phos.UsersFixtures.user_fixture()

    {:ok, memory} =
      attrs
      |> Enum.into(%{
        media: true,
        message: "some message",
        user_source_id: user_id
      })
      |> Phos.Message.create_memory()

    memory |> Phos.Repo.preload([:orb_subject, :user_source, :rel_subject])
  end

  @doc """
  Generate a reverie.
  """
  def reverie_fixture(attrs \\ %{}) do

    {:ok, reverie} =
      attrs
      |> Enum.into(%{
        read: ~U[2022-12-14 19:43:00Z],
      })
      |> Phos.Message.create_reverie()

    reverie
  end
end
