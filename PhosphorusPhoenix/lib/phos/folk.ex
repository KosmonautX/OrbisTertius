defmodule Phos.Folk do
  @moduledoc """
  Users to User context.
  """

  import Ecto.Query, warn: false
  use Nebulex.Caching
  alias Phos.Repo
  alias Phos.Users.{User, RelationBranch, RelationRoot}

  #@ttl :timer.hours(1)

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
    |> Repo.insert()
    |> case do
         {:ok, rel} = data ->
           rel = rel |> Repo.preload([:initiator])
           spawn(fn ->
             case rel.initiator do
               %{integrations: %{fcm_token: token}} -> Fcmex.Subscription.subscribe("FLK.#{rel.acceptor_id}", token)
               _ -> nil
             end

             Phos.Notification.target("'USR.#{rel.acceptor_id}' in topics",
               %{title: "#{rel.initiator.username} requested to be your ally"},
               PhosWeb.Util.Viewer.user_relation_mapper(rel))
           end)
           data
         err -> err
       end
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
    |> case do
         {:ok, rel} = data ->
           rel = rel |> Repo.preload([:acceptor])
           spawn(fn ->

             case rel.acceptor do
               %{integrations: %{fcm_token: token}} -> Fcmex.Subscription.subscribe("FLK.#{rel.initiator_id}", token)
               _ -> nil
             end

             Phos.Notification.target("'USR.#{rel.initiator_id}' in topics",
               %{title: "#{rel.acceptor.username} has accepted your request to become your ally"},
               PhosWeb.Util.Viewer.user_relation_mapper(rel))
           end)
           data
         err -> err
       end
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
  def pending_requests(user, page \\ 1, sort_attribute \\ :inserted_at, limit \\ 15)
  def pending_requests(%Phos.Users.User{id: id}, page, sort_attribute, limit), do: pending_requests(id, page, sort_attribute, limit)
  def pending_requests(user_id, page, sort_attribute, limit) do
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
  def friend_requests(user, page \\ 1, sort_attribute \\ :inserted_at, limit \\ 15)
  def friend_requests(%Phos.Users.User{id: id}, page, sort_attribute, limit), do: friend_requests(id, page, sort_attribute, limit)
  def friend_requests(user_id, page, sort_attribute, limit) do
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
  def friends(user_id, page \\ 1, sort_attribute \\ :completed_at, limit \\ 15)
  def friends(%Phos.Users.User{id: id}, page, sort_attribute, limit), do: friends(id, page, sort_attribute, limit)

  ## cache invalidation when updated needed
  #@decorate cacheable(cache: Cache, key: {User, :friends, [user_id, page, sort_attribute, limit]}, opts: [ttl: @ttl])

  def friends({user_id, your_id}, page, sort_attribute, limit) do
    query = from r in Phos.Users.RelationBranch,
      where: r.user_id == ^user_id and not is_nil(r.completed_at),
      left_join: friend in assoc(r, :friend),
      select: friend,
      left_join: mutual in assoc(friend, :relations),
      on: mutual.friend_id == ^your_id,
      left_join: root in assoc(mutual, :root),
      select_merge: %{self_relation: root}

    Repo.Paginated.all(query, page, sort_attribute, limit)
  end


  def friends(user_id, page, sort_attribute, limit) do
    query = from r in RelationBranch,
      where: not is_nil(r.completed_at),
      where: r.user_id == ^user_id,
      preload: [:root, :friend]

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
    #|> Kernel.++([user_id])
    |> do_get_feeds()
  end

  defp do_get_feeds(friend_ids), do: Phos.Action.list_orbs([initiator_id: friend_ids])

end
