defmodule Phos.Message do
  @moduledoc """
  The Message context.
  """

  import Ecto.Query, warn: false
  alias Phos.Repo

  defp cluster_enricher(%{data: memory} = resp),
    do: %{resp | data: Enum.map(memory, &(cluster_enricher(&1)))}

  defp cluster_enricher(%{message: "reply_com", com_subject: %{parent_id: parent_comment}} = m ),
     do: %{m | cluster_subject_id: parent_comment}
  defp cluster_enricher(%{message: "reply_orb_children"} = m ),
      do: %{m | cluster_subject_id: m.orb_subject_id}
  defp cluster_enricher(%{message: "reply_orb_root"}= m),
      do: %{m | cluster_subject_id: m.orb_subject_id}
  defp cluster_enricher(m),
     do: m

  def list_activity_by_user_id(yours, opts) when is_list(opts) do
    Phos.PlatformNotification.Store
    |> where([n], n.recipient_id == ^yours)
    |> join(:inner, [n], m in assoc(n, :memory), as: :memory)
    |> select([_n, m], m)
    |> join(:inner, [_n, m], u in assoc(m, :user_source))
    |> join(:left, [_n, m, _u], c in assoc(m, :com_subject))
    |> join(:left, [_n, m, _u, _c], o in assoc(m, :orb_subject))
    |> select_merge([_n, m, u, c, o], %{m | user_source: u, com_subject: c, orb_subject: o})
    |> Repo.Paginated.all([{:sort_attribute, {:memory , :inserted_at}} | opts])
    |> cluster_enricher()
  end

  @doc """
  Returns paginated call of the last message between each unique subject source destination triplet

  ## Examples

      iex> last_messages()
      [%Echo{}, ...]

  """

  def last_messages_by_relation(id, page, sort_attribute \\ :updated_at, limit \\ 12) do
    Phos.Users.RelationBranch
    |> where([b], b.user_id == ^id)
    |> join(:inner, [b], r in assoc(b, :root), as: :relation)
    |> select([_b, r], r)
    |> join(:inner, [_b, r], m in assoc(r, :last_memory))
    |> join(:left, [_b, r, m], o in assoc(m, :orb_subject))
    |> select_merge([_b, r, m, o], %{last_memory: %{m | orb_subject: o}})
    |> order_by([_b, r, _m], desc: r.updated_at)
    |> Repo.Paginated.all(page: page, sort_attribute: {:relation, sort_attribute}, limit: limit)
  end

  def last_messages_by_orb_within_relation({rel_id, _yours}, opts) when is_list(opts) do
    Phos.Message.Memory
    |> where([m], m.rel_subject_id == ^rel_id and not is_nil(m.orb_subject_id))
    |> preload([:orb_subject])
    |> Repo.Paginated.all(opts)
  end

  def last_messages_by_orb_within_relation(
        {rel_id, _yours},
        page,
        sort_attribute \\ :inserted_at,
        limit \\ 12
      ) do
    Phos.Message.Memory
    |> where([m], m.rel_subject_id == ^rel_id and not is_nil(m.orb_subject_id))
    |> preload([:orb_subject])
    |> Repo.Paginated.all(page, sort_attribute, limit)
  end

  @doc """
  Returns paginated call by cursorof the messages by relation

  ## Examples

      iex> list_messages_by_relation()
      [%Echo{}, ...]

  """

  def list_messages_by_relation({rel_id, _yours}, opts \\ []) when is_list(opts) do
    sort_attr = Keyword.get(opts, :sort_attribute, :inserted_at)
    limit = Keyword.get(opts, :limit, 12)

    query =
      Phos.Message.Memory
      |> where([m], m.rel_subject_id == ^rel_id)
      |> preload([:user_source, :orb_subject, mem_subject: [:user_source]])

    case Keyword.get(opts, :page) do
      nil -> Repo.Paginated.all(query, opts)
      page -> Repo.Paginated.all(query, page, sort_attr, limit)
    end
  end

  def list_messages_by_user(user, opts \\ [])
  def list_messages_by_user(%Phos.Users.User{id: id}, opts), do: list_messages_by_user(id, opts)

  def list_messages_by_user(user_id, opts) when is_bitstring(user_id) do
    user_id
    |> query_message_by_user()
    |> preload(last_memory: [:user_source, :rel_subject])
    |> Repo.Paginated.all(opts)
  end

  defp query_message_by_user(user_id) do
    Phos.Users.RelationRoot
    |> where([r], not is_nil(r.last_memory_id))
    |> where([r], r.initiator_id == ^user_id or r.acceptor_id == ^user_id)
  end

  @doc """
  Returns paginated call of the messages by orb

  ## Examples

      iex> list_messages_by_pair()
      [%Echo{}, ...]

  """

  def list_messages_by_orb({orb_id, _yours}, page, sort_attribute \\ :inserted_at, limit \\ 12) do
    Phos.Message.Memory
    |> where([m], m.orb_subject_id == ^orb_id)
    |> preload([:user_source])
    |> Repo.Paginated.all(page, sort_attribute, limit)
  end

  @doc """
  Returns paginated call of the messages by location

  ## Examples

      iex> list_messages_by_pair()
      [%Echo{}, ...]

  """
  def list_messages_by_geohashes(hash, opts\\ []) when is_integer(hash) do
    yesterday = NaiveDateTime.utc_now() |> NaiveDateTime.add(-60 * 60 * 24 * 100)
    Phos.Message.Memory
    |> where([m], m.loc_subject_id == ^hash and m.inserted_at > ^yesterday)
    |> preload([:user_source, :orb_subject, mem_subject: [:user_source]])
    |> Repo.Paginated.all(opts)
  end



  alias Phos.Message.Memory

  @doc """
  Returns the list of memories.

  ## Examples

      iex> list_memories()
      [%Memory{}, ...]

  """
  def list_memories do
    Repo.all(Memory)
    |> Repo.preload([:orb_subject, :user_source, :rel_subject])
  end

  @doc """
  Gets a single memory.

  Raises `Ecto.NoResultsError` if the Memory does not exist.

  ## Examples

      iex> get_memory!(123)
      %Memory{}

      iex> get_memory!(456)
      ** (Ecto.NoResultsError)

  """
  def get_memory!(id),
    do:
      Repo.get!(Memory, id)
      |> Repo.preload([:orb_subject, :user_source, :rel_subject])

  @doc """
  Create a Message.

  ## Examples

    iex> create_message(%{field: value})
    {:ok, %Memory{}}

    iex> create_message(%{field: bad_value})
    {:error, %Ecto.Changeset{}}

  """

  def create_message(
        %{"id" => _mem_id, "user_source_id" => _u_id, "rel_subject_id" => rel_id} = attrs
      ) do
    with rel = Phos.Folk.get_relation!(rel_id),
         mem_changeset <-
           Phos.Message.Memory.gen_changeset(%Memory{}, attrs)
           |> Ecto.Changeset.put_assoc(:last_rel_memory, rel),
         {:ok, memory} <- Repo.insert(mem_changeset) do
      memory
      |> Repo.preload([:orb_subject, :mem_subject,  :user_source, [rel_subject: :branches]])
      |> tap(&Phos.PubSub.publish(&1, {:memory, "formation"}, &1.rel_subject.branches))
      |> (&{:ok, &1}).()
    else
      {:error, err} -> {:error, err}
      _ -> {:error, :not_found}
      end
  end

    def create_message(%{"id" => _mem_id, "user_source_id" => _u_id, "loc_subject_id" => loc_id} = attrs) do
      with loc <- Phos.Terra.get_or_create_loc(loc_id),
      {:ok, memory} <- %Memory{}
      |> Memory.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:last_loc_memory, loc)
      |> Repo.insert() do
        memory
        |> Repo.preload([:orb_subject, :user_source, :loc_subject, mem_subject: [:user_source]])
        |> tap(&Phos.PubSub.publish(&1, {:memory, "assembly"}, &1.loc_subject))
        |> (&({:ok, &1})).()
      else
        {:error, err} -> {:error, err}

      _ -> {:error, :not_found}
      end
  end

    @doc """
  Creates a memory.

  ## Examples

      iex> create_memory(%{field: value})
      {:ok, %Memory{}}

      iex> create_memory(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_memory(attrs \\ %{})

  def create_memory(%{"id" => _id} = attrs) do
    %Memory{}
    |> Memory.changeset(attrs)
    |> Repo.insert()
  end

  def create_memory(attrs) do
    %Memory{}
    |> Memory.changeset(attrs |> Map.put(:id, Ecto.UUID.generate()))
    |> Repo.insert()
  end

  @doc """
  Updates a memory.

  ## Examples

      iex> update_memory(memory, %{field: new_value})
      {:ok, %Memory{}}

      iex> update_memory(memory, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_memory(%Memory{} = memory, attrs) do
    memory
    |> Memory.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a memory.

  ## Examples

      iex> delete_memory(memory)
      {:ok, %Memory{}}

      iex> delete_memory(memory)
      {:error, %Ecto.Changeset{}}

  """
  def delete_memory(%Memory{} = memory) do
    Repo.delete(memory)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking memory changes.

  ## Examples

      iex> change_memory(memory)
      %Ecto.Changeset{data: %Memory{}}

  """
  def change_memory(%Memory{} = memory, attrs \\ %{}) do
    Memory.changeset(memory, attrs)
  end

  alias Phos.Message.Reverie

  @doc """
  Returns the list of reveries.

  ## Examples

      iex> list_reveries()
      [%Reverie{}, ...]

  """
  def list_reveries do
    Repo.all(Reverie)
  end

  @doc """
  Gets a single reverie.

  Raises `Ecto.NoResultsError` if the Reverie does not exist.

  ## Examples

      iex> get_reverie!(123)
      %Reverie{}

      iex> get_reverie!(456)
      ** (Ecto.NoResultsError)

  """
  def get_reverie!(id), do: Repo.get!(Reverie, id)

  @doc """
  Creates a reverie.

  ## Examples

      iex> create_reverie(%{field: value})
      {:ok, %Reverie{}}

      iex> create_reverie(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_reverie(attrs \\ %{}) do
    %Reverie{}
    |> Reverie.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a reverie.

  ## Examples

      iex> update_reverie(reverie, %{field: new_value})
      {:ok, %Reverie{}}

      iex> update_reverie(reverie, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_reverie(%Reverie{} = reverie, attrs) do
    reverie
    |> Reverie.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a reverie.

  ## Examples

      iex> delete_reverie(reverie)
      {:ok, %Reverie{}}

      iex> delete_reverie(reverie)
      {:error, %Ecto.Changeset{}}

  """
  def delete_reverie(%Reverie{} = reverie) do
    Repo.delete(reverie)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking reverie changes.

  ## Examples

      iex> change_reverie(reverie)
      %Ecto.Changeset{data: %Reverie{}}

  """
  def change_reverie(%Reverie{} = reverie, attrs \\ %{}) do
    Reverie.changeset(reverie, attrs)
  end
end
