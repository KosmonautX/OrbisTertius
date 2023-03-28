defmodule Phos.External.GoogleCert do
  use HTTPoison.Base
  use Retry

  #Ensure that the ID token was signed by the private key corresponding to the token's kid claim.
  #Grab the public key from https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com
  #and use a JWT library to verify the signature. Use the value of max-age in the Cache-Control header of the response
  #from that endpoint to know when to refresh the public keys.


  def get_Cert() do
    retry with: exponential_backoff() |> randomize |> expiry(10_000) do
      get("")
    after
      {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: head}} ->
         ttl = case Regex.named_captures(~r/max-age=(?<ttl>\d+)/, :proplists.get_value("Cache-Control", head, nil) || :proplists.get_value("cache-control", head, nil) || "") do
           %{"ttl" => ttl} ->
             String.to_integer(ttl)
             |> (&(floor(&1 / 100) * 100)).()

             _ -> 0
         end

        {:ok, %{cert: body, exp: ttl}}
    else
      err -> err
    end
  end

  def process_request_url(_url), do: "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
  #def process_request_url(_url), do: "https://www.googleapis.com/robot/v1/metadata/x509/#{System.get_env("FYR_EMAIL")}"


  def process_response_body(body), do: body |> Jason.decode!()

  def process_request_body(body) when is_map(body), do: Jason.encode!(body)
  def process_request_body(body), do: body

 end
