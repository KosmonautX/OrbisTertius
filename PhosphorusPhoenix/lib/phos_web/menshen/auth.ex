defmodule PhosWeb.Menshen.Auth do
  import Joken.Config

  def validate(token) do
    validator = default_claims(default_exp: 1212, iss: "Princeton")  |> add_claim("sub", nil, &(&1 == "ScratchBac"))
    Joken.verify_and_validate(validator,token,Joken.Signer.parse_config(:menshenSB))
  end
end
