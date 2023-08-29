defmodule Phos.TeleBot.Cache do
  use Nebulex.Cache,
    otp_app: :phos,
    adapter: Nebulex.Adapters.Partitioned
    # default storage adapter: Nebulex.Adapters.Local
end
