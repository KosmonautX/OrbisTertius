defmodule Phos.External.HeimdallrClient do
  use HTTPoison.Base

  def get_dyn_user(id), do: List.first(Phos.External.HeimdallrClient.get!("query/get_users/" <> id).body)

  def post_orb(orbs) when is_list(orbs), do: Phos.External.HeimdallrClient.post("tele/post_orb",
        orbs |> post_orb_mapper())

  def post_orb(orb) when is_map(orb), do: Phos.External.HeimdallrClient.post("tele/post_orb",
        [orb]|> post_orb_mapper())


  def process_request_url(url) do
    config()
    |> Keyword.get(:base_url, {System, :get_env, "https://borbarossa.scratchbac.org/api"})
    |> define_module()
    |> parse_url(url)
  end

  def process_response_body(body) do
    body
    |> Jason.decode()
    # |> Map.take(@expected_fields)
    # |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end

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
  defp post_orb_mapper(orbs), do: PhosWeb.Util.Viewer.post_orb_mapper(orbs)

  defp define_module({module, fun, args}), do: apply(module, fun, args)
 end
