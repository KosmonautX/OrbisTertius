defmodule PhosWeb.Menshen.Role.Pleb do
  use Joken.Config, default_signer: :menshenSB

  add_hook Joken.Hooks.RequiredClaims, [:sub, :role, :iss, :exp, :user_id]

  @impl Joken.Config
  def token_config do
    default_claims(default_exp: 1212, iss: "Princeton", skip: [:jti, :nbf, :aud])
    |> add_claim("sub", fn -> "ScratchBac" end, &(&1 == "ScratchBac"))
    |> add_claim("role", fn -> "pleb" end, &(&1 in ["pleb", "boni"]))

  end
 end
