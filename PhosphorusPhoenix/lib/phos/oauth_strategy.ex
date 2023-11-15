defmodule Phos.OAuthStrategy do
  import Phoenix.VerifiedRoutes

  @spec request(atom()) :: {:ok, map()} | {:error, term()}
  def request(provider, format \\ "html") do
    config = config!(provider, format)
    case config[:strategy].authorize_url(config) do
      {:ok, %{url: url, session_params: session_params}} ->
        {url, session_params}
      _ -> :error
    end
  end

  @spec callback(atom(), map(), map()) :: {:ok, map()} | {:error, term()}
  def callback(provider, params, session_params \\ %{})
  def callback(provider, %{"format" => "json"} = params, session_params) do
    config =
      provider
      |> config!("json")
      |> Assent.Config.put(:session_params, session_params)

    config[:strategy].callback(config, params)
  end

  def callback("telegram", %{"id" => id} = params, _session_params) do
    data_check_string = params
    |> Map.delete("hash")
    |> Enum.map_join("\n", fn {key, val} -> "#{key}=#{val}" end)
    hash = :crypto.mac(:hmac,
      :sha256,
      :crypto.hash(:sha256, System.get_env("TELEGRAM_BOT_ID")),
      data_check_string)
      |> Base.encode16(case: :lower)
    if hash == params["hash"] && (System.os_time(:second) - 60*5 < params["auth_date"]) do
      user = params
      |> Map.put("sub", id)
      |> Map.put("provider", "telegram")
      |> Map.delete("id")
      {:ok, %{user: user}}
    else
      {:error, params}
    end
  end
  def callback("telegram", params, _session_params), do: {:error, params}

  def callback(provider, params, session_params) do
    if params["state"] == session_params[:state] && (System.os_time(:second) - 60*5 < session_params[:time]) do
      config =
        provider
        |> config!("html")
        |> Assent.Config.put(:session_params, session_params)

      config[:strategy].callback(config, params)
    else
      {:error, params}
    end
  end

  @spec telegram() :: map()
  def telegram() do
    conf = config!("telegram", "html")
    default_host = path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/auth/telegram/callback")
    host = case Keyword.get(conf, :host) do
             nil -> default_host
             "" -> default_host
             h -> h
           end
    path = Keyword.get(conf, :redirect_uri)
    Keyword.put(conf, :redirect_uri, host <> path)
    |> Keyword.put(:host, host)
    |> Enum.into(%{})
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

  defp https_auth(uri) when is_binary(uri) do
    uri
    |> URI.new()
    |> case do
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
    PhosWeb.Endpoint.url() <> path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/auth/#{provider}/callback.json")
    |> https_auth()
  end
  defp redirect_uri(:telegram, _), do: PhosWeb.Endpoint.url() <> path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/auth/telegram/callback") |> https_auth()

  defp redirect_uri(provider, _) do
    PhosWeb.Endpoint.url() <> path(PhosWeb.Endpoint, PhosWeb.Router, ~p"/auth/#{provider}/callback")
    |> https_auth()
  end
end
