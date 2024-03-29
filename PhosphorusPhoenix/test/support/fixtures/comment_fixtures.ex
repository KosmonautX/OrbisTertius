defmodule Phos.CommentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Phos.Action` context.
  """
  alias PhosWeb.Utility.Encoder
  import Phos.UsersFixtures
  @doc """
  Generate a comment.
  """
  def comment_fixture(attrs \\ %{}) do
    %{id: user_id} = user_fixture()
    case attrs do
      %{parent_path: parent_path} ->
        generated_id = Ecto.UUID.generate()
        {:ok, comment} =
          attrs
          |> Enum.into(%{id: generated_id, initiator_id: user_id,  body: "some body", path: Encoder.encode_lpath(generated_id, parent_path), active: true})
          |> Phos.Comments.create_comment()

        comment |> Phos.Repo.preload([:orb,:initiator])
      _ ->
        generated_id = Ecto.UUID.generate()
        {:ok, comment} =
          attrs
          |> Enum.into(%{id: generated_id, initiator_id: user_id, body: "some body", path: Encoder.encode_lpath(generated_id), active: true})
          |> Phos.Comments.create_comment()

        comment |> Phos.Repo.preload([:orb,:initiator])

    end
  end
end
