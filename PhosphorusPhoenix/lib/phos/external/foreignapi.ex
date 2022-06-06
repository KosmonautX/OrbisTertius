defmodule Phos.External.HeimdallrClient do
  use HTTPoison.Base

  def get_fyr_id(id) do
    Phos.External.HeimdallrClient.get!("query/get_users/" <> id).body
    |> process_response_body()
    |> List.first()
    |> Map.get("user_id")
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
