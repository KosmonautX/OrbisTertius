defmodule Phos.Cache do
  use Nebulex.Cache,
    otp_app: :phos,
    adapter: Nebulex.Adapters.Partitioned
end
