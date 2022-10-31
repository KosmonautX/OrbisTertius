defmodule Phos.External.GoogleIdentity do
  use HTTPoison.Base

  def gen_idToken(fyr_id) do
    #break into with
    {:ok, resp = %HTTPoison.Response{}} = post("verifyCustomToken", %{token: create_custom_token(fyr_id),
                                                                     returnSecureToken: true})
    resp.body["idToken"]
  end

  ## Full API Documentation
  # https://github.com/googleapis/google-api-go-client/blob/main/identitytoolkit/v3/identitytoolkit-api.json
  def process_request_url(url) do
    "https://www.googleapis.com/identitytoolkit/v3/relyingparty/" <> url <> "?key=#{System.get_env("LOCAL_FYR")}"
  end

  def process_response_body(body), do: body |> Jason.decode!()

  def process_request_body(body) when is_map(body), do: Jason.encode!(body)

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
     |> JOSE.JWK.from_pem()
     |> JOSE.JWT.sign(%{"alg" => "RS256"}, payload)
     |> JOSE.JWS.compact()
     |> elem(1)
  end
end
