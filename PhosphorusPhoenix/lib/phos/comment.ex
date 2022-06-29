defmodule Phos.Comments do
  @moduledoc """
  The Action context.
  """

  import Ecto.Query, warn: false
  alias Phos.Repo
  alias Phos.Action.{Orb, Location, Orb_Payload, Orb_Location}
  alias Phos.Comments.{Comment}

  alias Ecto.Multi

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment)
  end

#   @doc """
#   Creates a comment.

#   ## Examples

#       iex> create_comment(orb, %{field: new_value})
#       {:ok, %Orb{}}

#       iex> create_comment(orb, %{field: bad_value})
#       {:error, %Ecto.Changeset{}}

#   """
def create_comment(attrs \\ %{}) do
  %Comment{}
  |> Comment.changeset(attrs)
  |> Repo.insert()
end

#   @doc """
#   Gets a single orb.

#   Raises `Ecto.NoResultsError` if the Orb does not exist.

#   ## Examples

#       iex> get_orb!(123)
#       %Orb{}

#       iex> get_orb!(456)
#       ** (Ecto.NoResultsError)

#   """
#

  def get_comment!(id), do: Repo.get!(Comment, id) |> Repo.preload([:initiator])

  def get_comments_by_orb(id) do
    query =
      Comment
      |> where([e], e.orb_id == ^id)
      |> preload(:initiator)
      |> order_by(desc: :inserted_at)

    Repo.all(query)
  end

  def get_orb_by_fyr(id), do: Repo.get_by(Phos.Users.User, fyr_id: id)

#   @doc """
#   Updates a comment.

#   ## Examples

#       iex> update_orb(orb, %{field: new_value})
#       {:ok, %Orb{}}

#       iex> update_orb(orb, %{field: bad_value})
#       {:error, %Ecto.Changeset{}}

#   """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  #   @doc """
#   Updates a orb.

#   ## Examples

#       iex> update_orb!(%{field: value})
#       %Orb{}

#       iex> Need to Catch error state

#   """

  def update_comment!(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset_edit(attrs)
    |> Repo.update!()
    |> Repo.preload([:initiator, :orbs])
  end

#   @doc """
#   Deletes a orb.

#   ## Examples

#       iex> delete_orb(orb)
#       {:ok, %Orb{}}

#       iex> delete_orb(orb)
#       {:error, %Ecto.Changeset{}}

#   """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

#   @doc """
#   Returns an `%Ecto.Changeset{}` for tracking orb changes.

#   ## Examples

#       iex> change_orb(orb)
#       %Ecto.Changeset{data: %Orb{}}

#   """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end
end
