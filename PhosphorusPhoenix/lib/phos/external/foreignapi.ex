defmodule Phos.External.HeimdallrClient do
  use HTTPoison.Base

  def get_dyn_user(id) do
    List.first(Phos.External.HeimdallrClient.get!("query/get_users/" <> id).body)
  end

  def process_request_url(url) do
    "https://borbarossa.scratchbac.org/api/" <> url
  end

  def process_response_body(body) do
    body
    |> Jason.decode!()
    # |> Map.take(@expected_fields)
    # |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end
end
