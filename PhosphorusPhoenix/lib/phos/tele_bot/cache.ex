defmodule TeleBot.Cache do
  use Nebulex.Cache,
    otp_app: :phos,
    adapter: Nebulex.Adapters.Local
end
