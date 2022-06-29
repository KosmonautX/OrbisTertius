defmodule Phos.External.HeimdallrClient do
  use HTTPoison.Base

  def get_dyn_user(id) do
    List.first(Phos.External.HeimdallrClient.get!("query/get_users/" <> id).body)
  end

  def authorization do
    #TODO: how the user can get the long lived jwt token
    "bearer code implementation"
  end

  def process_request_url(url) do
    config()
    |> Keyword.get(:base_url, "https://borbarossa.scratchbac.org/api")
    |> parse_url(url)
  end

  def process_response_body(body) do
    body
    |> Jason.decode!()
    # |> Map.take(@expected_fields)
    # |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end

  def process_request_headers(headers) do
    auth_method =
      config()
      |> Keyword.get(:authorization)
      |> define_module()
    auth = "Bearer " <> auth_method
    Keyword.put(headers, :authorization, auth)
  end

  defp config do
    Application.get_env(:phos, __MODULE__, [])
  end

  defp parse_url(base, "/" <> path = url) do
    case String.ends_with?(base, "/") do
      true -> Kernel.<>(base, path)
      _ -> Kernel.<>(base, url)
    end
  end
  defp parse_url(base, url), do: parse_url(base, "/" <> url)

  defp define_module({module, fun, args}), do: apply(module, fun, args)
  defp define_module(auth), do: auth
end
