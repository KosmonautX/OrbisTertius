defmodule Phos.Users do
  @moduledoc """
  The Action context.
  """

  import Ecto.Query, warn: false
  alias Phos.Repo
  alias Phos.Users.{User, Public_Profile, Private_Profile}

  alias Ecto.Multi

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User |> preload(:public_profile) |> preload(:private_profile))
  end

#   @doc """
#   Gets a single user.

#   Raises `Ecto.NoResultsError` if the User does not exist.

#   ## Examples

#       iex> get_user!(123)
#       %User{}

#       iex> get_user!(456)
#       ** (Ecto.NoResultsError)

#   """
#
  def get_location_pref(type, id) do
    query =
      User
      |> where([e], e.fyr_id == ^id)
    Repo.all(query)
    |> Enum.map(fn orb -> orb.geohash end)
    # |> Enum.filter(fn orb -> Map.get()orb.type == type end)
  end

#   @doc """
#   Creates a user.

#   ## Examples

#       iex> create_user(%{field: value})
#       {:ok, %User{}}

#       iex> create_user(%{field: bad_value})
#       {:error, %Ecto.Changeset{}}

#   """

  def create_user(attrs \\ %{}) do
      # attrs
    # |> Map.put("id", generated_id)
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  # def create_public_profile(attrs \\ %{}) do
  #   %Public_Profile{}
  #   |> Public_Profile.changeset(attrs)
  #   |> Repo.insert()
  # end

  # def create_private_profile(attrs \\ %{}) do
  #   %Private_Profile{}
  #   |> Private_Profile.changeset(attrs)
  #   |> Repo.insert()
  # end

  # def create_user(attrs \\ %{}) do

    # generated_id = Ecto.UUID.generate()
    # attrs = attrs
    # |> Map.put("id", generated_id)
    # |> Map.put("user_id", generated_id)
    # # |> Map.put("public_profile_id", generated_id)
    # # |> Map.put("private_profile_id", generated_id)


    # IO.inspect(attrs)
    # multi =
    #   Multi.new()
    #   |> Multi.insert(:insert_user, %User{} |> User.changeset(attrs))
    #   # |> Multi.insert(:insert_public_profile, %Public_Profile{} |> Public_Profile.changeset(attrs))
    #   # |> Multi.insert(:insert_private_profile, %Private_Profile{} |> Private_Profile.changeset(attrs))

    # case (Repo.transaction(multi)) do
    #   {:ok, results} ->
    #     IO.inspect results
    #     IO.puts "Ecto Multi Success"
    #     {:ok, results}
    #   {:error, :insert_public_profile, changeset, _changes} ->
    #     IO.puts "Public Profile insert failed"
    #     IO.inspect changeset.errors
    #     {:error, changeset}
    #   {:error, :insert_private_profile, changeset, _changes} ->
    #     IO.puts "Private insert failed"
    #     IO.inspect changeset.errors
    #     {:error, changeset}
    #   {:error, :insert_user, changeset, _changes} ->
    #     IO.puts "User insert failed"
    #     IO.inspect changeset.errors
    #     {:error, changeset}
    # end
  # end


#   @doc """
#   Updates a user.

#   ## Examples

#       iex> update_user(user, %{field: new_value})
#       {:ok, %User{}}

#       iex> update_user(user, %{field: bad_value})
#       {:error, %Ecto.Changeset{}}

#   """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

#   @doc """
#   Deletes a user.

#   ## Examples

#       iex> delete_user(user)
#       {:ok, %User{}}

#       iex> delete_user(user)
#       {:error, %Ecto.Changeset{}}

#   """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

#   @doc """
#   Returns an `%Ecto.Changeset{}` for tracking user changes.

#   ## Examples

#       iex> change_user(user)
#       %Ecto.Changeset{data: %User{}}

#   """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
