defmodule Phos.Message do
  @moduledoc """
  The Message context.
  """

  import Ecto.Query, warn: false
  alias Phos.Repo

  alias Phos.Message.Echo

  @doc """
  Returns the list of echoes.

  ## Examples

      iex> list_echoes()
      [%Echo{}, ...]

  """
  def list_echoes do
    Repo.all(Echo)
  end


  @doc """
  Returns paginated call of the last message between each unique subject source destination triplet

  ## Examples

      iex> first_echoes()
      [%Echo{}, ...]

  """

  def last_echoes(id, page, sort_attribute \\ :inserted_at, limit \\ 12) do
    archetype = "USR"
    Phos.Message.Echo
    |> where([e], e.source == ^id and e.source_archetype == ^archetype )
    |> or_where([e], e.destination == ^id and e.destination_archetype == ^archetype)
    |> distinct([e], [e.subject, e.source, e.destination])
    |> order_by([e], desc: e.inserted_at)
    |> Repo.Paginated.all(page, sort_attribute, limit)
  end

  @doc """
  Returns paginated call of the messages between for one unique source destination pair

  ## Examples

      iex> list_echoes()
      [%Echo{}, ...]

  """

  def list_echoes_by_pair({id, yours}, page, sort_attribute \\ :inserted_at, limit \\ 12) do
    archetype = "USR"
    Phos.Message.Echo
    |> where([e], (e.source == ^id and e.source_archetype == ^archetype) and (e.destination == ^yours and e.destination_archetype == ^archetype))
    |> or_where([e], (e.source == ^yours and e.source_archetype == ^archetype) and (e.destination == ^id and e.destination_archetype == ^archetype))
    #|> distinct([e], e.subject)
    |> order_by([e], desc: e.inserted_at)
    |> Repo.Paginated.all(page, sort_attribute, limit)
  end

  @doc """

  Query Builder for Symmetric Source & Destination

  ## Examples

      iex> list_echoes()
      [%Echo{}, ...]

  """

    def ur_call(archetype, id) do
    query = Phos.Message.Echo
    |> where([e], e.source == ^id and e.source_archetype == ^archetype )
    |> or_where([e], e.destination == ^id and e.destination_archetype == ^archetype)
    |> order_by([e], desc: e.inserted_at)
    Phos.Repo.all(query, limit: 8)
  end

  def usr_call(id) do
    ur_call("USR", id) #user-user specific call
  end


  @doc """
  Gets a single echo.

  Raises `Ecto.NoResultsError` if the Echo does not exist.

  ## Examples

      iex> get_echo!(123)
      %Echo{}

      iex> get_echo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_echo!(id), do: Repo.get!(Echo, id)

  @doc """
  Creates a echo.

  ## Examples

      iex> create_echo(%{field: value})
      {:ok, %Echo{}}

      iex> create_echo(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_echo(attrs \\ %{}) do
    %Echo{}
    |> Echo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a echo.

  ## Examples

      iex> update_echo(echo, %{field: new_value})
      {:ok, %Echo{}}

      iex> update_echo(echo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_echo(%Echo{} = echo, attrs) do
    echo
    |> Echo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a echo.

  ## Examples

      iex> delete_echo(echo)
      {:ok, %Echo{}}

      iex> delete_echo(echo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_echo(%Echo{} = echo) do
    Repo.delete(echo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking echo changes.

  ## Examples

      iex> change_echo(echo)
      %Ecto.Changeset{data: %Echo{}}

  """

  def change_echo(%Echo{} = echo, attrs \\ %{}) do
    Echo.changeset(echo, attrs)
  end

 end
