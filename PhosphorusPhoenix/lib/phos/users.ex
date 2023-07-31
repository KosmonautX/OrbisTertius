defmodule Phos.Users do
  @moduledoc """
  The Users context.
  """

  use Nebulex.Caching

  import Ecto.Query, warn: false
  alias Phos.Repo
  alias Phos.Users.{User, PrivateProfile, Auth}
  alias Phos.Cache
  alias Ecto.Multi

  @ttl :timer.hours(1)

  @doc """
  Returns the list of users.

  ## Examples

  iex> list_users()
  [%User{}, ...]

  """

  defguard is_uuid?(value)
  when is_bitstring(value) and
         byte_size(value) == 36 and
         binary_part(value, 8, 1) == "-" and
         binary_part(value, 13, 1) == "-" and
         binary_part(value, 18, 1) == "-" and
         binary_part(value, 23, 1) == "-"


  def list_users do
    query = from(u in User)
    Repo.all(query)
  end

  def list_users(limit) do
    query = from u in User, limit: ^limit
    Repo.all(query)
  end

  def list_users(limit, page) do
    User
    |> order_by([u], [u.username])
    |> Repo.Paginated.all(limit: limit, page: page, aggregate: false)
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
  def get_user_by_fyr(id), do: Repo.get_by(User, fyr_id: id) |> Repo.preload([:private_profile])

  @decorate cacheable(cache: Phos.Cache, key: {User, username})
  def get_user_by_username(username), do: Repo.get_by(User, username: username)

  def filter_user_by_username(username, limit, page) do
    search = "%#{username}%"
    User
    |> where([u], ilike(u.username, ^search))
    |> order_by([u], [u.username])
    |> Repo.Paginated.all(limit: limit, page: page, aggregate: false)
  end

  def get_user(id) when is_uuid?(id) do
    fetch_user()
    |> where([u], u.id == ^id)
    |> Repo.one()
  end

  def get_user(username) when is_binary(username) do
    fetch_user()
    |> where([u], u.username == ^username)
    |> Repo.one()
  end

  def fetch_user do
    from u in User
  end

  def get_admin do
    query = from u in User, where: u.email == "scratchbac@gmail.com"

    case Repo.one(query) do
      user = %User{} ->
        user

      nil ->
        query = from u in User, order_by: u.inserted_at, limit: 1
        Repo.one(query)
    end
  end

  def get_pte_profile_by_fyr(id) do
    query = from u in User, where: u.fyr_id == ^id

    case Repo.one(query) do
      %User{} = user -> {:ok, user}
      nil -> {:error, "Location not set"}
    end

    Repo.get_by(User |> preload(:private_profile), fyr_id: id)
  end

  def get_users_by_home(id, _locname) do
    query =
      from u in User,
        join: p in assoc(u, :private_profile),
        where: fragment("? <@ ANY(?)", ~s|{"id": "home"}|, p.geolocation),
        where: u.id == ^id

    # select: p.geolocation

    Repo.all(query |> preload(:private_profile))
  end

  @decorate cacheable(cache: Cache, key: {User, :find, id}, opts: [ttl: @ttl])
  def find_user_by_id(id) when is_uuid?(id) do
    query = from u in User,
    as: :user,
    where: u.id == ^id,
    limit: 1,
    inner_lateral_join:
    a_count in subquery(
      from(r in Phos.Users.RelationBranch,
        where: r.user_id == parent_as(:user).id and not is_nil(r.completed_at),
        select: %{count: count()}
      )
    ),
    select_merge: %{ally_count: a_count.count}

    case Repo.one(query) do
      %User{} = user -> {:ok, user |> Repo.preload(:private_profile)}
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

  def migrate_fyr_user(old_user, new_user) do
    old_changeset =
      old_user
      |> User.changeset(%{fyr_id: nil})

    new_changeset =
      new_user
      |> User.fyr_registration_changeset(%{fyr_id: old_user.fyr_id})

    with {:ok, _} <-
           Repo.transaction(
             Multi.new()
             |> Multi.update(:old_user, old_changeset)
             |> Multi.update(:new_user, new_changeset)
           ) do
      :ok
    else
      _ -> :error
    end
  end

  def migrate_user(attrs \\ %{}) do
    %User{}
    |> User.migration_changeset(attrs)
    |> Repo.insert()
  end

  def create_private_profile(attrs \\ %{}) do
    %PrivateProfile{}
    |> PrivateProfile.changeset(attrs)
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
  @decorate cache_evict(cache: Cache, key: {User, :find, user.id})
  def update_user(%User{} = user, attrs) do
    user
    |> User.personal_changeset(attrs)
    |> Repo.update()
  end

  @decorate cache_evict(cache: Cache, key: {User, :find, user.id})
  def update_territorial_user(%User{} = user, attrs) do
    user
    |> User.territorial_changeset(attrs)
    |> Repo.update()
  end

  defp terra_publisher(%Phos.Users.Geolocation{} = terr, %User{} = user) do
    Phos.PubSub.publish(terr , {:terra, "mutation"}, user)
  end

  @decorate cache_evict(cache: Cache, key: {User, :find, user.id})
  def update_integrations_user(%User{} = user, attrs) do
    user
    |> User.integration_changeset(attrs)
    |> Repo.update()
  end

  @decorate cache_evict(cache: Cache, key: {User, :find, user.id})
  def update_pub_user(%User{} = user, attrs) do
    user
    |> User.pub_profile_changeset(attrs)
    |> Repo.update()
  end

  @decorate cache_evict(cache: Cache, key: {User, :find, user.id})
  def update_user_profile(%User{} = user, attrs) do
    changeset = Ecto.Changeset.change(user.public_profile)
    user_changeset = Ecto.Changeset.change(user)
    userprofile_changeset = Ecto.Changeset.change(changeset, attrs)

    Ecto.Changeset.put_embed(user_changeset, :public_profile, userprofile_changeset)
    |> Phos.Repo.update()
  end

  #   @doc """
  #   Deletes a user.

  #   ## Examples

  #       iex> delete_user(user)
  #       {:ok, %User{}}

  #       iex> delete_user(user)
  #       {:error, %Ecto.Changeset{}}

  #   """
  @decorate cache_evict(cache: Cache, key: {User, :find, user.id})
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

  def get_user_by_telegram(id) when is_binary(id) do
    case do_query_from_auth(id, "telegram") do
      %Auth{user: user} ->
        {:ok, %{user | tele_id: id} }
      err -> {:error, err}
    end
  end

  def get_user_by_telegram(id), do: to_string(id) |> get_user_by_telegram()

  def telegram_user_exists?(id) when is_binary(id) do
    case do_query_from_auth(id, "telegram") do
      %Auth{} -> true
      _ -> false
    end
  end
  def telegram_user_exists?(id), do: to_string(id) |> telegram_user_exists?()


  @doc """
  Authenticate a user from oauth provider
  """
  def from_auth(%{"sub" => id, "provider" => provider} = resp) do
    case do_query_from_auth(to_string(id), provider) do
      nil -> create_new_user(id, provider, resp)
      %Auth{} = auth -> {:ok, auth.user}
      _ -> {:error, "Error occured"}
    end
  end

  defp do_query_from_auth(id, provider) when is_atom(provider),
    do: do_query_from_auth(id, Atom.to_string(provider))

  defp do_query_from_auth(id, provider) do
    Repo.one(
      from a in Auth,
      preload: [user: [[:private_profile, personal_orb: :locations]]],
      where: a.auth_id == ^id and a.auth_provider == ^provider,
      limit: 1
    )
  end

  defp create_new_user(id, provider, _params) when provider == "telegram" do
    params = %{
      auths: [
        %{
          auth_id: to_string(id),
          auth_provider: to_string(provider)
        }
      ],
      integrations: %{
        telegram_chat_id: to_string(id)
      },
      public_profile: %{birthday: "",
                        bio: "I'm new to Scratchbac!",
                        public_name: "",
                        occupation: "",
                        traits: [],
                        profile_pic: Enum.random(1..6),
                        banner_pic: Enum.random(1..6)}
    }

    %User{}
    |> User.telegram_changeset(params)
    |> Repo.insert()
  end


  defp create_new_user(id, provider, %{"email" => email}) do
    params = %{
      auth_id: id,
      auth_provider: to_string(provider),
      user: %{
        email: email
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

  def get_telegram_chat_ids_by_orb(%Phos.Action.Orb{central_geohash: nil}), do: []
  def get_telegram_chat_ids_by_orb(orb) do
    orb = orb |> Repo.preload([:initiator])
    telegram_chat_ids =
      :h3.parent(orb.central_geohash, 8)
      |> List.wrap()
      |> Phos.Action.telegram_chat_id_by_geohashes()
      |> Enum.reduce([],
       fn %{telegram_chat_id: chat_id}, acc when not is_nil(chat_id) ->
            [%{orb: orb, chat_id: chat_id} | acc]
          _, acc -> acc
      end)
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

  def get_user!(id), do: Repo.get!(User, id) |> Repo.preload([:private_profile, :personal_orb])

  def get_territorial_user!(id),
    do: Repo.get!(User, id) |> Repo.preload([:private_profile, personal_orb: :locations])

  def get_public_user(user_id, your_id) when is_uuid?(your_id) do
    Phos.Repo.one(
      from u in User,
      as: :user,
      where: u.id == ^user_id,
      left_join: branch in assoc(u, :relations),
      on: branch.friend_id == ^your_id,
      left_join: root in assoc(branch, :root),
      select: u,
      select_merge: %{self_relation: root},
      inner_lateral_join:
      a_count in subquery(
        from(r in Phos.Users.RelationBranch,
          where: r.user_id == parent_as(:user).id and not is_nil(r.completed_at),
          select: %{count: count()}
        )
      ), on: true,
      select_merge: %{ally_count: a_count.count})
  end

  def get_public_user(user_id, _) do
    Phos.Repo.one(
      from u in User,
      as: :user,
      where: u.id == ^user_id,
      inner_lateral_join:
      a_count in subquery(
        from(r in Phos.Users.RelationBranch,
          where: r.user_id == parent_as(:user).id and not is_nil(r.completed_at),
          select: %{count: count()}
        )
      ),
      select_merge: %{ally_count: a_count.count})
  end

  def get_public_user_by_username(username, your_id) do
    Phos.Repo.one(
      from u in User,
        where: u.username == ^username,
        left_join: branch in assoc(u, :relations),
        on: branch.friend_id == ^your_id,
        left_join: root in assoc(branch, :root),
        select: u,
        select_merge: %{self_relation: root}
    )
    |> Phos.Repo.Preloader.lateral(:orbs, limit: 5)
  end

  def get_private_profile!(id) do
    Repo.get!(PrivateProfile, id)
  end

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
  Registers an anonymous user.

  ## Examples

  iex> register_user(%{field: value})
  {:ok, %User{}}

  iex> register_user(%{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def claim_anon_user(%User{email: nil} = user, attrs) do
    user
    |> User.registration_changeset(attrs)
    |> Repo.update()
  end

  def claim_anon_user(_user, _attrs) do
    {:error, "email already registered for user"}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

  iex> change_user_registration(user)
  %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

  iex> change_user_email(user)
  %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
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
  Returns an `%Ecto.Changeset{}` for changing telegram login users.

  ## Examples

  iex> change_pub_profile(user)
  %Ecto.Changeset{data: %User{}}

  """
  def change_user_username(user, attrs \\ %{}) do
    User.post_registration_changeset(user, attrs)
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
  @decorate cache_evict(cache: Cache, key: {User, :find, user.id})
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

    Multi.new()
    |> Multi.update(:user, changeset)
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc """
  Delivers the update email instructions to the given user.

  ## Examples

  iex> deliver_update_email_instructions(user, current_email, &Routes.user_update_email_url(conn, :edit, &1))
  {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
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
  @decorate cache_evict(cache: Cache, key: {User, :find, user.id})
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Multi.new()
    |> Multi.update(:user, changeset)
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
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

    Repo.one(query)
    |> Repo.preload([:private_profile])
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
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
    Multi.new()
    |> Multi.update(:user, User.confirm_changeset(user))
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
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
  @decorate cache_evict(cache: Cache, key: {User, :find, user.id})
  def reset_user_password(user, attrs) do
    Multi.new()
    |> Multi.update(:user, User.password_changeset(user, attrs))
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

    ## Link Telegram -> Web

  @doc """
  Delivers the confirmation email instructions to the given user.

  ## Examples

  iex> deliver_user_confirmation_instructions(user, &Routes.user_confirmation_url(conn, :edit, &1))
  {:ok, %{to: ..., body: ...}}

  iex> deliver_user_confirmation_instructions(confirmed_user, &Routes.user_confirmation_url(conn, :edit, &1))
  {:error, :already_confirmed}

  """
  def deliver_telegram_bind_confirmation_instructions(%User{} = user, telegram_id, bindtelegram_url_fun)
      when is_function(bindtelegram_url_fun, 1) do

      {encoded_token, user_token} = UserToken.build_email_token_for_bind_account(user, telegram_id, "bind_telegram")
      Repo.insert!(user_token)
      UserNotifier.deliver_telegram_link_instructions(user, bindtelegram_url_fun.(encoded_token))
  end

  @doc """
  Binds a user by the given token.

  If the token matches, the user account is marked as confirmed, telegram_id is
  added to the user integrations and the token is deleted.
  """
  # def bind_user(token) do
  #   with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
  #        %User{} = user <- Repo.one(query),
  #        {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
  #     {:ok, user}
  #   else
  #     _ -> :error
  #   end
  # end

  def bind_user(token) do
    with {:ok, query} <- UserToken.verify_bindaccount_token_query(token, "bind_telegram"),
        user when not is_nil(user) <- Repo.one(query), # this user struct is a special struct with only email and telegram user
        {:ok, %{user: user}} <- Repo.transaction(bind_user_multi(user)) do
      {:ok, user}
    else
    _ ->
      :error
    end
  end

  def bind_user_multi(%{tele_user: %{integrations: %{telegram_chat_id: telegram_id}} = tele_user, email: email} = user) do
    main_user = get_user_by_email(email) |> Repo.preload([:auths])

    query =
      from a in Auth,
        where: a.auth_id == ^telegram_id and a.auth_provider == "telegram"
    auth = Repo.one(query)

    params = %{
      id: main_user.id,
      auths: [
        %{
          auth_id: telegram_id,
          auth_provider: "telegram"
        }
      ],
      integrations: %{
        telegram_chat_id: to_string(telegram_id)
      }
    }

    Multi.new()
    |> Multi.delete(:auth, auth)
    |> Multi.update(:user, User.telegram_changeset(main_user, params))
    # |> Multi.update(:user, User.confirm_changeset(user)) #might need another field? confirmed_at already exist before user is linked
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(tele_user, ["bind_telegram"]))
  end
end
