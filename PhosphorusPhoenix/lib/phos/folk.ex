defmodule Phos.Folk do
  @moduledoc """
  Users to User context.
  """

  import Ecto.Query, warn: false
  use Nebulex.Caching
  alias Phos.{Cache, Repo}
  alias Phos.Users.{User, RelationBranch, RelationRoot}

  @ttl :timer.hours(1)

  #   @doc """
  #   Gets a single Relation.

  #   Raises `Ecto.NoResultsError` if the Relation does not exist.

  #   ## Examples

  #       iex> get_relation!(123)
  #       %RelationRoot{}

  #       iex> get_relation!(456)
  #       ** (Ecto.NoResultsError)

  #   """
  def get_relation!(id), do: Repo.get!(RelationRoot, id)

  def get_relation_by_pair(self, other),
    do: Repo.get_by(RelationBranch, [user_id: self, friend_id: other])
    |> Phos.Repo.preload(:root)

  #   @doc """
  #   Creates a Relation.

  #   ## Examples

  #       iex> create_relation(%{field: value})
  #       {:ok, %Relation{}}

  #       iex> create_relation(%{field: bad_value})
  #       {:error, %Ecto.Changeset{}}

  #   """

  def create_relation(attrs \\ %{}) do
    %RelationRoot{}
    |> RelationRoot.gen_branches_changeset(attrs)
    |> Phos.Repo.insert()
  end

  #   @doc """
  #   Updates a relation.

  #   ## Examples

  #       iex> update_relation(relation, %{field: new_value})
  #       {:ok, %Relation{}}

  #       iex> update_relation(relation, %{field: bad_value})
  #       {:error, %Ecto.Changeset{}}

  #   """

  def update_relation(%RelationRoot{} = relation, attrs) do
    relation
    |> RelationRoot.mutate_state_changeset(attrs)
    |> Repo.update()
  end


  @doc """
  Deletes a relation.

  ## Examples

      iex> delete_relation(relation)
      {:ok, %Relation{}}

      iex> delete_relation(relation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_relation(%RelationRoot{} = relation) do
    Repo.delete(relation)
  end


  @doc """
  Add friend

  Request user as friend
  Accpetor cannot request a user as friend

  ## Examples:

  iex> add_friend(user_id_with_no_friends)
  {:ok, %Phos.Users.Relation{}}

  """
  @spec add_friend(requester_id :: Ecto.UUID.t(), acceptor_id :: Ecto.UUID.t()) :: {:ok, Phos.Users.Relation.t()} | {:error, Ecto.Changeset.t()}
  def add_friend(requester_id, acceptor_id) when requester_id != acceptor_id do
    payload = %{"initiator_id" => requester_id,
                "acceptor_id" => acceptor_id,
                "branches" => [%{"user_id" => acceptor_id, "friend_id"=> requester_id},
                               %{"user_id" => requester_id, "friend_id"=> acceptor_id}]}
    create_relation(payload)
  end
  def add_friend(_requester_id, _acceptor_id), do: {:error, "API not needed to connect to your own inner self"}

  @doc """
  List of user pending friends request

  This contains of user data

  ## Examples:

      iex> pending_requests(user_id_with_no_pending_requests)
      []

      iex> pending_requests(user_id)
      [%User{}, %User{}]

  """
  @spec pending_requests(user_id :: Ecto.UUID.t() | Phos.Users.User.t()) :: [Phos.Users.User.t()]
  def pending_requests(%Phos.Users.User{id: id}), do: pending_requests(id)
  def pending_requests(user_id, page, sort_attribute \\ :inserted_at, limit \\ 15) do
    query = from r in RelationRoot,
      where: r.initiator_id == ^user_id and r.state == "requested",
      preload: [:acceptor]

    Repo.Paginated.all(query, page, sort_attribute, limit)
  end

  @doc """
  List of requested friends

  This contains of user data

  ## Examples:

      iex> pending_requests(user_id_with_no_frind_requests)
      []

      iex> pending_requests(user_id)
      [%User{}, %User{}]

  """
  @spec friend_requests(user_id :: Ecto.UUID.t() | Phos.Users.User.t(), filters :: Keyword.t()) :: [Phos.Users.User.t()] | Phos.Users.User.t()
  def friend_requests(%Phos.Users.User{id: id}), do: friend_requests(id)
  def friend_requests(user_id, page, sort_attribute \\ :inserted_at, limit \\ 15) do
    query = from r in RelationRoot,
      where: r.acceptor_id == ^user_id and r.state == "requested",
      preload: [:initiator]


    Repo.Paginated.all(query, page, sort_attribute, limit)
  end

  @doc """
  List of friends

  This contains of user data

  ## Examples:

      iex> pending_requests(user_id_with_no_friends)
      []

      iex> pending_requests(user_id)
      [%User{}, %User{}]

  """
  @decorate cacheable(cache: Cache, key: {User, :friends, user_id}, opts: [ttl: @ttl])
  def friends(user_id, page, sort_attribute \\ :completed_at, limit \\ 15) do
    query = from r in RelationBranch,
      where: not is_nil(r.completed_at),
      where: r.user_id == ^user_id,
      preload: [:root]

    Repo.Paginated.all(query, page, sort_attribute, limit)
  end

  def friends_lite(user_id) do
    query = from r in RelationBranch,
      where: not is_nil(r.completed_at),
      where: r.user_id == ^user_id,
      select: r.friend_id

    Repo.all(query)
  end



  def feeds(%User{id: id} = _user), do: feeds(id)

  def feeds(user_id) do
    friends_lite(user_id)
    |> Kernel.++([user_id])
    |> do_get_feeds()
  end

  defp do_get_feeds(friend_ids), do: Phos.Action.list_orbs([initiator_id: friend_ids])

end
