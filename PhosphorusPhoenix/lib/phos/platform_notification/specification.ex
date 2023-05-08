defmodule Phos.PlatformNotification.Specification do

  alias Phos.PlatformNotification.{Template, Store}

  @callback parse(template :: Template.t() | map(), options :: list()) :: Template.parsed()
  @callback send(store :: Store.t()) :: :ok | :error
  @optional_callbacks parse: 2

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Phos.PlatformNotification.Specification

      @doc """
      Parse function used to parse common template to parsed template with value of user preference.
      If the options is nil or contains an empty value should replace with empty string.

      This abstraction should use inside the PlatformNotification.Consumer.
      """
      def parse(%Phos.PlatformNotification.Template{} = template, options) do
        keys =
          template
          |> Map.from_struct()
          |> Enum.reduce([], fn {k, v}, acc ->
            if v, do: [k | acc], else: acc
          end)

        %{
          "body" => replace_data_value(template.body, keys, options),
          "title" => replace_data_value(template.title, keys, options),
          "subtitle" => replace_data_value(template.subtitle, keys, options),
          "icon" => template.icon,
          "click_action" => template.click_action,
        }
      end
      defoverridable parse: 2

      defp replace_data_value(data, _keys, options) when data in ["", nil], do: ""
      defp replace_data_value(data, keys, options) do
        Enum.reduce(keys, data, fn v, acc ->
          String.replace(acc, "{#{v}}", Keyword.get(options, v, ""))
        end)
      end

      @doc """
      send function used to sending push or broadcast to specified user
      """
      def send(store) do
        :logger.error(%{
          label: {Phos.PlatformNotification, :no_send},
          report: %{
            module: __MODULE__,
            store: store
          }
        }, %{
          domain: [:phos],
          error_logger: %{tag: :error_msg}
        })
      end
      defoverridable send: 1
    end
  end
end
