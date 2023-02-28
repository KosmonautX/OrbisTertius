defmodule Phos.External.GoogleCert do
  use HTTPoison.Base
  use Retry


  def get_Cert() do
    retry with: exponential_backoff() |> randomize |> expiry(10_000) do
      get("")
    after
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:ok, body}
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
