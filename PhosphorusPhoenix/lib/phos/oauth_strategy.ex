defmodule Phos.OAuthStrategy do
  @spec request(atom()) :: {:ok, map()} | {:error, term()}
  def request(provider, format \\ "html") do
    config = config!(provider, format)

    case config[:strategy].authorize_url(config) do
      {:ok, %{url: url}} -> url
      _ -> :error
    end
  end

  @spec callback(atom(), map(), map()) :: {:ok, map()} | {:error, term()}
  def callback(provider, %{"format" => format} = params, session_params \\ %{}) do
    config =
      provider
      |> config!(format)
      |> Assent.Config.put(:session_params, session_params)

    config[:strategy].callback(config, params)
  end

  defp config!(provider, format) when is_binary(provider), do: String.to_existing_atom(provider) |> config!(format)
  defp config!(provider, format) when provider in [:google, :apple, :telegram] do
    Application.get_env(:phos, __MODULE__)
    |> Keyword.get(provider)
    |> case do
      nil -> raise "Configuration for #{provider} not found."
      config -> default_config(config, provider, format)
    end
  end
  defp config!(provider, _), do: raise "No provider configuration for #{provider}"

  defp default_config(config, provider, format) do
    case Keyword.get(config, :redirect_uri) do
      nil -> Keyword.put(config, :redirect_uri, PhosWeb.Router.Helpers.auth_url(PhosWeb.Endpoint, :callback, provider, [format: format]))
      _ -> config
    end
    |> Enum.map(fn {k, v} -> {k, value_mapper(v)}end)
  end

  defp value_mapper({module, atom, params}), do: apply(module, atom, params)
  defp value_mapper(type) when is_binary(type) or is_atom(type), do: type
  defp value_mapper(_), do: ""
end
