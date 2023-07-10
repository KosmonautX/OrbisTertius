defmodule Phos.Users.User do

  use Ecto.Schema
  import Ecto.Changeset
  alias Phos.Action.{Orb}
  alias Phos.Users.{PublicProfile, PrivateProfile, Auth, RelationBranch, Integrations}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "users" do
    field :email, :string
    field :username, :string
    field :role, :string
    field :media, :boolean, default: false
    field :fyr_id, :string

    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime

    has_many :orbs, Orb, references: :id, foreign_key: :initiator_id
    has_many :auths, Auth, references: :id, foreign_key: :user_id
    has_many :relations, RelationBranch, foreign_key: :user_id

    field :self_relation, :string, virtual: true
    field :profile_image, :string, virtual: true

    field :ally_count, :integer, default: 0, virtual: true
    field :mutual_count, :integer, default: 0, virtual: true
    field :mutual, :any, virtual: true

    # has_many :pending_relations, RelationBranch, foreign_key: :user_id, where: [completed_at: nil]
    has_many :allies, RelationBranch, foreign_key: :user_id, where: [completed_at: {:not, nil}]
    #has_many :allies, through: [:branches, :friend]

    has_one :personal_orb, Orb, foreign_key: :id
    has_one :private_profile, PrivateProfile, references: :id, foreign_key: :user_id
    embeds_one :public_profile, PublicProfile, on_replace: :update
    embeds_one :integrations, Integrations, on_replace: :update

    timestamps()
  end

  @doc false
  def changeset(%Phos.Users.User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :media, :email, :fyr_id])
    #|> validate_required(:email)
    |> cast_embed(:public_profile)
    |> cast_assoc(:private_profile)
    |> validate_username()
    |> unique_constraint(:fyr_id, name: :unique_fyr)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  def personal_changeset(%Phos.Users.User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :media])
    #|> validate_required(:email)
    |> cast_embed(:public_profile)
    |> cast_assoc(:personal_orb, with: &Orb.personal_changeset/2)
    |> validate_username()
  end

  def territorial_changeset(%Phos.Users.User{} = user, attrs) do
    user
    |> cast(attrs, [])
    |> cast_assoc(:personal_orb, with: &Orb.territorial_changeset/2)
    |> cast_embed(:public_profile, with: &PublicProfile.territorial_changeset/2)
    |> cast_assoc(:private_profile)
  end

  def integration_changeset(%Phos.Users.User{} = user, attrs) do
    user
    |> cast(attrs, [])
    |> cast_embed(:integrations)
  end

  @doc false
  def telegram_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, [:username, :email])
    |> cast_assoc(:auths, with: &Auth.changeset/2)
  end

  def post_registration_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required(:username)
    |> validate_username()
  end

  def migration_changeset(%Phos.Users.User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :media, :fyr_id])
    #|> validate_required(:email)
    |> cast_embed(:public_profile)
    |> cast_assoc(:private_profile)
    |> unique_constraint(:username, name: :unique_username)
    |> unique_constraint(:fyr_id, name: :unique_fyr)
  end

  def fyr_registration_changeset(%Phos.Users.User{} = user, attrs) do
    user
    |> cast(attrs, [:fyr_id])
    |> validate_required(:fyr_id)
    |> unique_constraint(:fyr_id, name: :unique_fyr)
  end

  def pub_profile_changeset(%Phos.Users.User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :media])
    |> cast_embed(:public_profile)
    |> validate_username()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :username])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_username(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_username(changeset, _opts \\ []) do
    changeset
    |> validate_format(:username, ~r/^[a-z0-9]*$/, message: "lower-case letters and numbers only")
    |> validate_length(:username, min: 5, max: 16)
    |> unique_constraint(:username, name: :unique_username)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Phos.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Phos.Users.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
