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
    %{id: user_id} = user_fixture()

    {:ok, orb} =
      attrs
      |> Enum.into(%{
        "id" => Ecto.UUID.generate(),
        "locations" => [623_276_216_934_563_839] |> Enum.map(fn hash -> %{"id" => hash} end),
        "title" => "some title",
        "active" => true,
        "extinguish" => %{day: 21, hour: 7, minute: 22, month: 5, year: 2022},
        "source" => :web,
        "initiator_id" => user_id,
        "payload" => %{
          "info" => "some info",
          "tip" => "some tip",
          "when" => "some when",
          "where" => "Singapore"
        }
      })
      |> Phos.Action.create_orb()

      orb |> Phos.Repo.preload([:locations, :blorbs])
  end

  @spec orb_fixture_no_location(any) ::
  nil | [%{optional(atom) => any}] | %{optional(atom) => any}
  def orb_fixture_no_location(attrs \\ %{}) do
    %{id: user_id} = user_fixture()

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

      orb |> Phos.Repo.preload([:locations, :initiator, :blorbs])
  end

  @doc """
  Generate a text blorb.
  """
  def blorb_fixture(attrs \\ %{}) do
    %{id: user_id} = user_fixture()
    {:ok, blorb} =
      attrs
      |> Enum.into(%{
          "id" => Ecto.UUID.generate(),
          "active" => true,
          "type" => "txt",
          "initiator_id" => user_id,
          "character" => %{"content" => "For him who has conquered the mind, the mind is the best of friends; but for one who has failed to do so, his very mind will be the greatest enemy."}
                   })
                   |> Phos.Action.create_blorb()
      blorb |> Phos.Repo.preload([:initiator])
  end

  def orb_permission_fixture(attrs \\ %{}) do
    orb  = Map.get(attrs, :orb, %{}) |> orb_fixture()
    user = Map.get(attrs, :user, %{}) |> user_fixture()
    action = Map.get(attrs, :action, :collab_invite)

    {:ok, permission} = Phos.Action.add_permission(orb, %{
      user: user,
      action: action
    })
    
    permission
  end
end
