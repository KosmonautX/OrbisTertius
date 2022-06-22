defmodule Phos.Users do
  @moduledoc """
  The Action context.
  """

  import Ecto.Query, warn: false
  alias Phos.Repo
  alias Phos.Users.{User, Public_Profile, Private_Profile, Auth}

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
  def get_user_by_fyr(id), do: Repo.get_by(User |> preload(:private_profile) |> preload(:public_profile), fyr_id: id)

  def get_pte_profile_by_fyr(id) do
    query = from u in User, where: u.fyr_id == ^id

    case Repo.one(query) do
      %User{} = user -> {:ok, user}
      nil -> {:error, "Location not set"}
    end
    Repo.get_by(User |> preload(:private_profile), fyr_id: id)
  end

  def get_users_by_home(id, locname) do
    query = from u in User,
      join: p in assoc(u, :private_profile),
      where: fragment("? <@ ANY(?)", ~s|{"id": "home"}|, p.geolocation)
      # select: p.geolocation

    Repo.all(query |> preload(:private_profile))
  end

  def get_pub_profile_by_fyr(id), do: Repo.get_by(User |> preload(:public_profile), fyr_id: id)

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

  def migrate_user(attrs \\ %{}) do
    %User{}
    |> User.migration_changeset(attrs)
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


  def update_pub_user(%User{} = user, attrs) do
    user
    |> User.pub_profile_changeset(attrs)
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

  alias Phos.Users.{User, UserToken, UserNotifier}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

    @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_pub_profile(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_pub_profile(user, attrs \\ %{}) do
    User.pub_profile_changeset(user, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc """
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_update_email_instructions(user, current_email, &Routes.user_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query) |> Repo.preload([:private_profile, :public_profile])
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &Routes.user_confirmation_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &Routes.user_confirmation_url(conn, :edit, &1))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &Routes.user_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end
end
