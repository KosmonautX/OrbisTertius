defmodule Phos.Admin.Token do
  use Joken.Config, default_signer: :menshenSB

  add_hook Joken.Hooks.RequiredClaims, [:sub, :role, :iss, :exp]

  @impl Joken.Config
  def token_config do
    default_claims(default_exp: 1212, iss: "Princeton", skip: [:jti, :nbf, :aud])
    |> add_claim("sub", fn-> "ScratchBac" end, &(&1 == "ScratchBac"))
    |> add_claim("role", fn -> "admin" end, &(&1 == "admin"))
  end
end
