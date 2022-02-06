defmodule Phos.Fyr.Task do
  use Task
  alias Phos.Fyr.Message

  def start_link(notification) do
    Task.start_link(__MODULE__, :run, [notification])
  end

  def run(notification) do
    Message.push(notification)
  end
end
