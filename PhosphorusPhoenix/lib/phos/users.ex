defmodule Phos.Users do
  @moduledoc """
  The Action context.
  """

  import Ecto.Query, warn: false
  alias Phos.Repo
  alias Phos.Users.{User, Auth}

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
#   Gets a single user.

#   Raises `Ecto.NoResultsError` if the User does not exist.

#   ## Examples

#       iex> get_user!(123)
#       %User{}

#       iex> get_user!(456)
#       ** (Ecto.NoResultsError)

#   """
#
  def get_location_pref(id) do
    query =
      User
      |> where([e], e.fyr_id == ^id)
    Repo.all(query)
  end

  def find_user_by_id(id) when is_bitstring(id) do
    query = from u in User, where: u.id == ^id, limit: 1
    case Repo.one(query) do
      %User{} = user -> {:ok, user}
      nil -> {:error, "User not found"}
    end
  end

  def authenticate(email, password) when is_bitstring(email) and is_bitstring(password) do
    email = String.downcase(email)
    query = from u in User, where: u.email == ^email, limit: 1
    case Repo.one(query) do
      %User{} = user -> Argon2.check_pass(user, password)
      _ -> authenticate(nil, nil)
    end
  end
  def authenticate(_, _), do: {:error, "Email or password not match"}

#   @doc """
#   Creates a user.

#   ## Examples

#       iex> create_user(%{field: value})
#       {:ok, %User{}}

#       iex> create_user(%{field: bad_value})
#       {:error, %Ecto.Changeset{}}

#   """

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

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

  @doc """
  Authenticate a user from oauth provider
  """
  def from_auth(%Ueberauth.Auth{uid: id, provider: provider} = resp) do
    case do_query_from_auth(id, provider) do
      nil -> create_new_user(id, provider, resp)
      %Auth{} = auth -> {:ok, auth.user}
      _ -> {:error, "Error occured"}
    end
  end

  defp do_query_from_auth(id, provider) when is_atom(provider), do:
    do_query_from_auth(id, Atom.to_string(provider))
  defp do_query_from_auth(id, provider) do
    Repo.one(
      from a in Auth,
      preload: [:user],
      where: a.auth_id == ^id and a.auth_provider == ^provider,
      limit: 1
    )
  end

  defp create_new_user(id, provider, %Ueberauth.Auth{info: info} = auth) do
    params = %{
      auth_id: id,
      auth_provider: Atom.to_string(provider),
      user: %{
        email: info.email,
        userprofile: %{
          birthday: info.birthday,
          bio: info.description
        }
      }
    }
    %Auth{}
    |> Auth.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, auth} -> {:ok, auth.user}
      error -> error
    end
  end
end
