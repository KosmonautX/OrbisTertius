defmodule Phos.External.HeimdallrClient do
  use HTTPoison.Base
  use Retry

  def get_dyn_user(id) do
    do_get_users(id)
    |> List.first()
  end

  defp do_get_users(id) do
    retry with: constant_backoff(100) |> Stream.take(5) do
      get("query/get_users/" <> id)
    after
      {:ok, response} -> response.body
    else
      error -> raise ArgumentError, inspect(error)
    end
  end

  def post_orb(orbs) when is_list(orbs), do: do_post_orb(orbs)
  def post_orb(orbs) when is_map(orbs), do: do_post_orb([orbs])

  defp do_post_orb(orbs) do
    retry with: constant_backoff(100) |> Stream.take(5) do
      post("tele/post_orb", orbs)
    after
      result -> PhosWeb.Util.Viewer.post_orb_mapper(result)
    else
      error -> error
    end
  end

  def process_request_url(url) do
    config()
    |> Keyword.get(:base_url, "https://borbarossa.scratchbac.org/api")
    |> define_module()
    |> parse_url(url)
  end

  def process_response_body(body) do
    body
    |> Jason.decode!()
    # |> Map.take(@expected_fields)
    # |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end

  def process_request_body(""), do: ""

  def process_request_body(body), do: body |> Jason.encode!()


  def process_request_headers(headers), do: headers ++
    [{:authorization, authorize!()}, {:"Content-Type", "application/json"}]

  defp config do
    Application.get_env(:phos, __MODULE__, [])
  end

  defp authorize!, do: PhosWeb.Menshen.Auth.generate_boni!()

  defp parse_url(base, "/" <> path = url) do
    case String.ends_with?(base, "/") do
      true -> Kernel.<>(base, path)
      _ -> Kernel.<>(base, url)
    end
  end

  defp parse_url(base, url), do: parse_url(base, "/" <> url)

  defp define_module({module, fun, args}), do: apply(module, fun, args)
  defp define_module(arg), do: arg
 end
