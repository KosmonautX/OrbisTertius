defmodule Phos.Fyr.Task do
  use Task
  alias Phos.Fyr.Message

  def start_link(notification) do
    Task.start_link(__MODULE__, :run, [notification])
  end

  def run(notification) do
    case now = Message.push(notification) do #inspect notif full response body
    #case Message.push(notification) do
      %{response: :success} -> :ok

      %{error: nil} -> IO.inspect(now) #some response failure

      %{error: reason} -> IO.inspect(reason)
   end
  end
end
