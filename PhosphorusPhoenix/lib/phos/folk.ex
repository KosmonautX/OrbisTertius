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
  #
  def get_relation!(id),
    do: Repo.get!(RelationRoot, id) |> Repo.preload(:last_memory)
  def get_relation!(id, your_id),
    do: Repo.get!(RelationRoot, id)
    |> self_initiated_enricher(your_id)

  defp self_initiated_enricher(%{data: roots} = resp, your_id),
    do: %{resp | data: Enum.map(roots, &(self_initiated_enricher(&1, your_id)))}
  defp self_initiated_enricher(%RelationRoot{} = rel_root, your_id) do
    %{rel_root | self_initiated: your_id == rel_root.initiator_id}
    |> case do
         %{self_initiated: true} = rel ->
           rel |> Repo.preload([:acceptor])
         %{self_initiated: false} = rel ->
           rel |> Repo.preload([:initiator])
    end
  end

  def get_relation_by_pair(self, other),
    do: Repo.get_by(RelationBranch, [user_id: self, friend_id: other])
    |> Phos.Repo.preload(:root)

  @doc """
  Returns paginated call of the last message between each unique subject source destination triplet

  ## Examples

      iex> last_messages()
      [%Echo{}, ...]

  """

  def last_messages_by_relation(id, page, sort_attribute \\ :updated_at, limit \\ 12) do
    RelationBranch
    |> where([b], b.user_id == ^id)
    |> join(:inner, [b], r in assoc(b, :root), as: :relation)
    |> select([_b, r], r)
    |> join(:inner, [_b, r], m in assoc(r, :last_memory))
    |> join(:left, [_b, r, m], o in assoc(m, :orb_subject))
    |> select_merge([_b, r, m, o], %{last_memory: %{m | orb_subject: o}})
    |> order_by([_b, r, _m], desc: r.updated_at)
    |> Repo.Paginated.all([page: page, sort_attribute: {:relation , sort_attribute}, limit: limit])
    |> self_initiated_enricher(id)
  end

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
             Phos.Notification.target("'USR.#{rel.acceptor_id}' in topics",
               %{title: "#{rel.initiator.username} requested to be your ally 🤝"},
               %{action_path: "/folkland/self/requests"})
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
             Phos.Notification.target("'USR.#{rel.initiator_id}' in topics",
               %{title: "#{rel.acceptor.username} accepted your ally request ❤️"},
               %{action_path: "/userland/others/#{rel.acceptor_id}"})
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
    from(m in Phos.Message.Memory, where: m.rel_subject_id == ^relation.id)
    |> Phos.Repo.all()
    |> Enum.map(&Phos.Message.delete_memory(&1))

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

  This contains of user data. This actually friends/4
  if you've seen friends/1, friends/2 and friends/3 is the default version of friends/4. Default options are listed below:
    - page: an integer and have default: 1
    - sort_attribute: an atom, default: :completed_at
    - limit: an integer, default: 15

  friends/1 can take first argument as %User{id: id} (a user id), which means is a string or {friend_id, user_id} which is pair of bitstring

  friends/2 take first argument as same as friends/1, and second argument is page

  friends/3 take first argument as same as friends/2, and second argument is sort_attribute

  friends/4 take first argument as same as friends/3, and second argument is limit

  ## Examples:

      iex> friends(user_id)
      %{
        data: [],
        meta: %{
          pagination: %{
            current: 1,
            downstream: false,
            end: 0,
            start: 0,
            total: 0,
            upstream: false
          }
        }
      }

      iex> friends(user_id)
      %{
        data: [%RelationBranch{}, %RelationBranch{}],
        meta: %{
          pagination: %{
            current: 1,
            downstream: false,
            end: 0,
            start: 0,
            total: 0,
            upstream: false
          }
        }
      }

      iex> friends({friend_id, user_id})
      %{
        data: [%RelationBranch{}, %RelationBranch{}],
        meta: %{
          pagination: %{
            current: 1,
            downstream: false,
            end: 0,
            start: 0,
            total: 0,
            upstream: false
          }
        }
      }

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

  def notifiers_by_friends(user_id) do
    query = from r in RelationBranch,
      where: not is_nil(r.completed_at) and r.user_id == ^user_id,
      inner_join: friend in assoc(r, :friend),
      distinct: friend.integrations["fcm_token"],
      select: friend.integrations

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
