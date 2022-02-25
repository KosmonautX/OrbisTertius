defmodule Phos.Repo do
  use Ecto.Repo,
    otp_app: :phos,
    adapter: Ecto.Adapters.Postgres
end
