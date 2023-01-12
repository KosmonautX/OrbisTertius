defmodule Phos.Comments do
  @moduledoc """
  The Action context.
  """

  import Ecto.Query, warn: false
  import EctoLtree.Functions, only: [nlevel: 1]

  alias Phos.Repo
  alias Phos.Comments.Comment


  @doc """
  Returns the list of comments.

  ## Examples

  iex> list_comments()
  [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment) |> Repo.preload([:initiator])
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
    |> case do
         {:ok, %{parent_id: p_id} = comment} = data when not is_nil(p_id)->
           comment = comment |> Repo.preload([:initiator])
           spawn(fn ->
             case comment.initiator do
               %{integrations: %{fcm_token: token}} -> Fcmex.Subscription.subscribe("COM.#{comment.id}", token)
               _ -> nil
             end
             Phos.Notification.target("'COM.#{p_id}' in topics && !('USR.#{comment.initiator_id}' in topics)",
               %{title: "#{comment.initiator.username} commented on your comment",
                 body: comment.body
               },
               PhosWeb.Util.Viewer.comment_mapper(comment))
            end)
           data
        {:ok, %{orb_id: o_id} = comment} = data ->
           comment = comment |> Repo.preload([:initiator])
           spawn(fn ->
             case comment.initiator do
               %{integrations: %{fcm_token: token}} -> Fcmex.Subscription.subscribe("COM.#{comment.id}", token)
               _ -> nil
             end
             Phos.Notification.target("'ORB.#{o_id}' in topics && !('USR.#{comment.initiator_id}' in topics)",
               %{title: "#{comment.initiator.username} commented on your orb",
                 body: comment.body
               },
               PhosWeb.Util.Viewer.comment_mapper(comment))
           end)
           data
         err -> err
       end
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
  #

  def get_comment(id), do: Repo.get(Comment, id) |> Repo.preload([:initiator])
  def get_comment!(id), do: Repo.get!(Comment, id) |> Repo.preload([:initiator])

  def get_descendents_comment(id) do
    query =
      from c in Comment,
      as: :c,
      where: c.parent_id == ^id,
      preload: [:initiator],
      order_by: [desc: c.inserted_at],
      inner_lateral_join: sc in subquery(
        from sc in Comment,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ),
      select_merge: %{child_count: sc.count}
    Repo.all(query)
  end


  def get_root_comments_by_orb(id) do
    query =
      from c in Comment,
      as: :c,
      where: c.orb_id == ^id,
      where: nlevel(c.path) == 1,
      preload: [:initiator],
      order_by: [desc: c.inserted_at],
      inner_lateral_join: sc in subquery(
        from sc in Comment,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ),
      select_merge: %{child_count: sc.count}

    Repo.all(query)

  end

  def get_descendents_comment(id, page, sort_attribute \\ :inserted_at, limit \\ 12) do
    query =
      from c in Comment,
      as: :c,
      where: c.parent_id == ^id,
      preload: [:initiator],
      inner_lateral_join: sc in subquery(
        from sc in Comment,
        select: %{count: count()}
      ),
      select_merge: %{child_count: sc.count}

    Repo.Paginated.all(query, page, sort_attribute, limit)
  end

  def get_root_comments_by_orb(id, page, sort_attribute \\ :inserted_at, limit \\ 12) do
    query =
      from c in Comment,
      as: :c,
      where: c.orb_id == ^id,
      where: nlevel(c.path) == 1,
      preload: [:initiator],
      inner_lateral_join: sc in subquery(
        from sc in Comment,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ),
      select_merge: %{child_count: sc.count}

    Repo.Paginated.all(query, page, sort_attribute, limit)
  end



  def get_comments_by_orb(id) do
    query = Comment
    |> where([e], e.orb_id == ^id)
    |> preload(:initiator)
    |> order_by(desc: :inserted_at)

    Repo.all(query)
  end

  def get_comment_count_by_orb(id) do
    query =
      Comment
      |> where([e], e.orb_id == ^id)
    |> select([e], count(e))
    Repo.one(query)
  end


  # Gets child comments 1 level down only
  def get_child_comments_by_orb(id, path) do
    path = path <> ".*{1}"

    query =
      from c in Comment,
      as: :c,
      where: c.orb_id == ^id,
      where: fragment("? ~ ?", c.path, ^path),
      preload: [:initiator],
      inner_lateral_join: sc in subquery(
        from sc in Comment,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ),
      select_merge: %{child_count: sc.count}

    Repo.all(query)
  end

  # Gets ancestors down up all levels only
  # TODO: Get root comments together
  def get_ancestor_comments_by_orb(orb_id, path) do
    query =
      from c in Comment,
      as: :c,
      where: c.orb_id == ^orb_id,
      where: fragment("? @> ?", c.path, ^path),
      preload: [:initiator],
      inner_lateral_join: sc in subquery(
        from sc in Comment,
        where: sc.parent_id == parent_as(:c).id,
        select: %{count: count()}
      ),
      select_merge: %{child_count: sc.count}

    Repo.all(query)
  end

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
    |> Comment.changeset_edit(attrs)
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
