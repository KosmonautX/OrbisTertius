defmodule Phos.TelegramNotification.Pusher do
  use GenStage, restart: :permanent

  alias Phos.TelegramNotification, as: TN
  alias Phos.Telebot

  def start_link(_ok) do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    # Process.send_after(self(), {:ask, from}, 5000)

    {:consumer, %{}, subscribe_to: [TN.Dispatcher]}
  end

  def handle_events(events, from, producers) do
    Phos.TeleBot.dispatch_messages(events)

    {:noreply, [], producers}
  end
end
