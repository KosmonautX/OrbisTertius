defmodule Phos.PlatformNotification.Store do
  use Ecto.Schema

  import Ecto.Changeset

  @moduledoc """
  Store module is extensible from default notification type

  Struct for this module is:
    - action_path: can be string or nil value. this value used to navigate to application
    - active: boolean value to identify this notification active or not. default false
    - actor: this can be map or struct, can be either ORB, USR, Memories, etc
    - id: ID used to retry the notification
    - template_id: Linked to Template module
    - retry_after: If notification cannot sent, should retry after x minutes. default: 1
    - retry_attempt: Tries to sent notification, default: 0
    - notify_type: notification type, 1 for them self, 2 for around them


  """

  @type t :: %__MODULE__{
    success: boolean(),
    spec: Phos.PlatformNotification.t(),
    id: non_neg_integer(),
    retry_attempt: non_neg_integer(),
    next_execute_at: DateTime.t(),
    error_reason: String.t(),
  }

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "notifications" do
    field :success, :boolean
    field :spec, :map
    field :retry_attempt, :integer, default: 0
    field :next_execute_at, :naive_datetime
    field :error_reason, :string

    belongs_to :template, Phos.PlatformNotification.Template, references: :id, type: Ecto.UUID
    belongs_to :memory, Phos.Message.Memory, references: :id, type: Ecto.UUID
    belongs_to :recipient, Phos.Users.User, references: :id, type: Ecto.UUID

    timestamps()
  end

  @doc """
  changeset function used to change map to Ecto.Changeset.t()
  """
  @spec changeset(store :: t(), attrs :: map()) :: Ecto.Changeset.t()
  def changeset(store, attrs) do
    store
    |> cast(attrs, [:id, :template_id, :recipient_id, :success, :spec, :retry_attempt, :next_execute_at, :error_reason])
    |> cast_assoc(:memory, with: &Phos.Message.Memory.changeset/2)
    |> validate_required([:spec, :id])
  end
end
