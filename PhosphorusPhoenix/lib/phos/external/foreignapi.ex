defmodule Phos.External.ForeignAPI do
  use HTTPoison.Base

  def get_fyr_id(id) do
    HTTPoison.get!("https://borbarossa.scratchbac.org/api/query/get_users/" <> id).body
    |> process_response_body()
    |> List.first()
    |> Map.get("user_id")
  end

  def process_request_url(url) do
    "https://borbarossa.scratchbac.org" <> url
  end

  def process_response_body(body) do
    body
    |> Jason.decode!()
    # |> Map.take(@expected_fields)
    # |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end
end
