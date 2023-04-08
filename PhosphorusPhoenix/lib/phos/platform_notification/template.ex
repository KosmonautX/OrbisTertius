defmodule Phos.PlatformNotification.Template do
  use Ecto.Schema

  import Ecto.Changeset

  @moduledoc """
  Template module used to store template of notification

  Template might be stored in single ets file and can be backed up to s3 or can be save to external database (like: notion, ecto or etc)
  
  Template must be have unique identifier to identify their function or behavior, specified field of the Template listed below:
    - id: Unique identifier, must be string and always downcase.
    - body: Body of the notification, long text with parsed content
    - subtitle: Subtitle of the notification, can be blank
    - receiver_name: Receiver name of the notification. this item should be parsed and can change dynamically
    - sender_name: Sender name of the notification. this item should be parsed and can change dynamically
    - event_name: Event name of the notification. this item should be parsed and can change dynamically
  """

  @type t() :: %__MODULE__{
    id: String.t(),
    body: String.t(),
    title: String.t(),
    subtitle: String.t(),
    receiver_name: boolean(),
    sender_name: boolean(),
    event_name: boolean(),
    icon: String.t(),
    click_action: String.t(),
  }

  @type parsed() :: %{
    title: String.t(),
    subtitle: String.t(),
    body: String.t(),
    icon: Strint.t(),
    click_action: String.t(),
  }

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "notification_templates" do
    field :key, :string
    field :body, :string
    field :title, :string
    field :subtitle, :string
    field :receiver_name, :boolean
    field :sender_name, :boolean
    field :event_name, :boolean
    field :icon, :string
    field :click_action, :string
  end
  
  @doc """
  changeset function used to change map to struct and do some validations
  """
  @spec changeset(tempale :: t(), attrs :: map()) :: Ecto.Changeset.t()
  def changeset(template, attrs) do
    template
    |> cast(attrs, [:id, :key, :body, :title, :subtitle, :receiver_name, :sender_name, :event_name, :icon, :click_action])
    |> validate_required([:id, :key, :body, :title])
    |> unique_constraint(:body)
  end

  @doc """
  parse function used to parse %__MODULE__{} to notification mao()
  """
  @spec parse(data :: t() | map(), options :: Keywod.t()) :: parsed()
  def parse(%__MODULE__{} = data, options) do
    keys =
      data
      |> Map.from_struct()
      |> Enum.reduce([], fn {k, v}, acc ->
        case v do
          true -> [k | acc]
          _ -> acc
        end
      end)

    %{
      body: replace_data_value(data.body, keys, options),
      title: replace_data_value(data.title, keys, options),
      subtitle: replace_data_value(data.subtitle, keys, options),
      icon: data.icon,
      click_action: data.click_action,
    }
  end
  def parse(data, _options) when is_map(data), do: data

  defp replace_data_value(data, _keys, _options) when data in ["", nil], do: ""
  defp replace_data_value(data, keys, options) do
    Enum.reduce(keys, data, fn v, acc ->
      String.replace(acc, "{#{v}}", Keyword.get(options, v, ""))
    end)
  end
end
