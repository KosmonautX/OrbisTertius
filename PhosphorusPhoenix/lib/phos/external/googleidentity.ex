defmodule Phos.External.GoogleIdentity do
  use HTTPoison.Base
  use Retry

  def link_email(fyr_id, email) do
    case set_account_info(%{idToken: gen_id_token(fyr_id), email: email}) do
    {:ok, %HTTPoison.Response{body: %{"email" => email}}} -> email

    {:error, err} -> raise RuntimeError, HTTPoison.Error.message(err)
   end
  end

  def gen_custom_token(fyr_id) do
    create_custom_token(fyr_id)
  end

  def gen_id_token(fyr_id) do
    case verify_custom_token(%{token: create_custom_token(fyr_id), returnSecureToken: true}) do
    {:ok, %HTTPoison.Response{body: %{"idToken" => idToken}}} -> idToken

    {:error, err} -> raise RuntimeError, HTTPoison.Error.message(err)
   end
  end

  ## Full API Documentation
  # https://github.com/googleapis/google-api-go-client/blob/main/identitytoolkit/v3/identitytoolkit-api.json
  def process_request_url(url) do
    "https://www.googleapis.com/identitytoolkit/v3/relyingparty/" <> url <> "?key=#{System.get_env("LOCAL_FYR")}"
  end

  def process_response_body(body), do: body |> Jason.decode!()

  def process_request_body(body) when is_map(body), do: Jason.encode!(body)

  defp verify_custom_token(params) do
    retry with: exponential_backoff() |> randomize |> expiry(10_000) do
      post("verifyCustomToken", params)
    after
      response -> response
    else
      err -> err
    end
  end

  defp set_account_info(params) do
    retry with: exponential_backoff() |> randomize |> expiry(10_000) do
      post("setAccountInfo", params)
    after
      response -> response
    else
      err -> err
    end
  end

  defp create_custom_token(uid) when is_binary(uid) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    email = System.get_env("FYR_EMAIL")
    payload = %{
      "iss" => email,
      "sub" => email,
      "aud" =>
        "https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit",
      "iat" => now,
      "exp" => now + 888,
      "uid" => uid,
      "claims" => %{}
    }

     System.get_env("FYR_KEY")
     |> String.replace("\\n", "\n")
     |> JOSE.JWK.from_pem()
     |> JOSE.JWT.sign(%{"alg" => "RS256"}, payload)
     |> JOSE.JWS.compact()
     |> elem(1)
  end
 end
