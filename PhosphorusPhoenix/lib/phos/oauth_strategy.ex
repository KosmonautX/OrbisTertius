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
      nil ->
        uri = redirect_uri(provider, format)
        Keyword.put(config, :redirect_uri, uri)
      _ -> config
    end
    |> Enum.map(fn {k, v} -> {k, value_mapper(v)}end)
  end

  defp value_mapper({module, atom, params}), do: apply(module, atom, params)
  defp value_mapper(type) when is_binary(type) or is_atom(type), do: type
  defp value_mapper(_), do: ""

  defp https_auth(url) when is_binary(url) do
    case URI.new(url) do
      {:ok, uri} -> https_auth(uri)
      _ -> ""
    end
  end
  defp https_auth(%URI{host: "localhost"} = uri), do: URI.to_string(uri)
  defp https_auth(%URI{} = uri) do
    uri
    |> Map.put(:scheme, "https")
    |> URI.to_string()
  end

  defp redirect_uri(provider, "json") do
    PhosWeb.Router.Helpers.auth_url(PhosWeb.Endpoint, :callback, provider, [format: "json"])
    |> https_auth()
  end
  defp redirect_uri(provider, _) do
    PhosWeb.Router.Helpers.auth_url(PhosWeb.Endpoint, :callback, provider)
    |> https_auth()
  end
end
