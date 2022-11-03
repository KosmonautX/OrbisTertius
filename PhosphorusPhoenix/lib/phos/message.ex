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
  Returns paginated call of the first message between each unique source destination pair

  ## Examples

      iex> first_echoes()
      [%Echo{}, ...]

  """

  def first_echoes() do

  end

  @doc """
  Returns paginated call of the messages between for one unique source destination pair

  ## Examples

      iex> list_echoes()
      [%Echo{}, ...]

  """

  def echoes_by_pair() do

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
