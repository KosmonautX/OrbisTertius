defmodule Phos.Terra do
  @moduledoc """

  The Terra context.

  """

  import Ecto.Query, warn: false
  alias Phos.Repo

  alias Phos.Action.Location

  @doc """
  Returns the list of terras.

  ## Examples

      iex> list_terras()
      [%Location{}, ...]

  """
  def location_by_hash(hashes) do
    # seed hashes for sg or map into enum
    from(l in Phos.Action.Location,
          where: l.id in ^hashes,
          preload: [last_memory: [:user_source]],
          select: {l.id, l})
          |> Phos.Repo.all()
          |> Enum.into(%{})
  end

  @doc """
  Gets a single loc.

  Raises `Ecto.NoResultsError` if the Location does not exist.

  ## Examples

      iex> get_loc!(123)
      %Location{}

      iex> get_loc!(456)
      ** (Ecto.NoResultsError)

  """
  def get_loc!(id), do: Repo.get!(Location, id)

  def get_loc(id), do: Repo.get(Location, id)

  def get_or_create_loc(id) do
    case get_loc(id) do
      nil ->
        create_loc(%{id: id})
      loc -> loc
    end
  end

  @doc """
  Creates a loc.

  ## Examples

      iex> create_loc(%{field: value})
      {:ok, %Location{}}

      iex> create_loc(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_loc(attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a loc.

  ## Examples

      iex> update_loc(loc, %{field: new_value})
      {:ok, %Location{}}

      iex> update_loc(loc, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_loc(%Location{} = loc, attrs) do
    loc
    |> Location.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a loc.

  ## Examples

      iex> delete_loc(loc)
      {:ok, %Location{}}

      iex> delete_loc(loc)
      {:error, %Ecto.Changeset{}}

  """
  def delete_loc(%Location{} = loc) do
    Repo.delete(loc)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking loc changes.

  ## Examples

      iex> change_loc(loc)
      %Ecto.Changeset{data: %Location{}}

  """
  def change_loc(%Location{} = loc, attrs \\ %{}) do
    Location.changeset(loc, attrs)
  end
end
