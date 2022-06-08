defmodule Phos.Users do
  @moduledoc """
  The Action context.
  """

  import Ecto.Query, warn: false
  alias Phos.Repo
  alias Phos.Users.{User}

  alias Ecto.Multi

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
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
  def get_location_pref(id) do
    query =
      User
      |> where([e], e.fyr_id == ^id)
    Repo.all(query)
  end

  def get_orb!(id), do: Repo.get!(Orb, id)
  def get_orbs_by_geohash(id) do
    query =
      Orb_Location
      |> where([e], e.location_id == ^id)
      |> preload(:orbs)

    Repo.all(query, limit: 32)
  end

#   @doc """
#   Creates a orb.

#   ## Examples

#       iex> create_orb(%{field: value})
#       {:ok, %Orb{}}

#       iex> create_orb(%{field: bad_value})
#       {:error, %Ecto.Changeset{}}

#   """

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

#   @doc """
#   Updates a orb.

#   ## Examples

#       iex> update_orb(orb, %{field: new_value})
#       {:ok, %Orb{}}

#       iex> update_orb(orb, %{field: bad_value})
#       {:error, %Ecto.Changeset{}}

#   """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

#   @doc """
#   Deletes a orb.

#   ## Examples

#       iex> delete_orb(orb)
#       {:ok, %Orb{}}

#       iex> delete_orb(orb)
#       {:error, %Ecto.Changeset{}}

#   """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

#   @doc """
#   Returns an `%Ecto.Changeset{}` for tracking orb changes.

#   ## Examples

#       iex> change_orb(orb)
#       %Ecto.Changeset{data: %Orb{}}

#   """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
