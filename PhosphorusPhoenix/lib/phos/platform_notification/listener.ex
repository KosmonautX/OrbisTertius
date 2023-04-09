defmodule Phos.PlatformNotification.Listener do
  use GenServer

  require Logger

  alias Phos.PlatformNotification, as: PN

  @channel "table_changes"

  def start_link(channel), do: GenServer.start_link(__MODULE__, channel, name: __MODULE__)

  @impl true
  def init(_channel) do
    Logger.info("Starting #{__MODULE__} with channel subscription: #{inspect(@channel)}")

    config = Phos.Repo.config()
    {:ok, pid} = Postgrex.Notifications.start_link(config)
    {:ok, ref} = Postgrex.Notifications.listen(pid, @channel)
    {:ok, {pid, @channel, ref}}
  end

  @impl true
  def handle_info({:notification, _pid, _ref, @channel, payload}, state) do
    case Jason.decode(payload) do
      {:ok, data} -> process_data(data)
      _ -> :error
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  # for comments notification
  defp process_data(%{"table" => table, "id" => id, "type" => type}) when table == "comments" and type == "INSERT" do
    comment = Phos.Comments.get_comment(id) |> Phos.Repo.preload([:parent])

    comment
    |> notify_parent_element()
    |> notify_initiator()
    |> notify_self()
  end

  # for orb notification
  defp process_data(%{"table" => table}) when table == "orbs" do
    # TODO: To be implemented
    :ok
  end

  defp notify_parent_element(%{initiator_id: init_id, parent: %{initiator_id: parent_init_id}} = comment) when init_id != parent_init_id do
    PN.notify({"broadcast", "COMMENT", comment.id, "replied_comment"},
      to: parent_init_id,
      notification: %{
        title: "#{comment.initiator.username} replied",
        body: comment.body
      }, data: %{
        action_path: "/comland/comments/children/#{comment.id}"
      })
    comment
  end
  defp notify_parent_element(comment), do: comment

  defp notify_initiator(%{initiator_id: init_id, orb: %{initiator_id: orb_init_id}, parent: %{initiator_id: parent_init_id}} = comment)
    when orb_init_id not in [init_id, parent_init_id] do
    PN.notify({"broadcast", "COMMENT", comment.id, "replied_orb"},
      to: orb_init_id,
      notification: %{
        title: "#{comment.initiator.username} replied to a comment withtin your post",
        body: comment.body,
      }, data: %{
        action_path: "/comland/comments/children/#{comment.id}"
      })
    comment
  end
  defp notify_initiator(comment), do: comment

  defp notify_self(%{orb: %{initiator_id: orb_init_id}, initiator_id: init_id} = comment) when orb_init_id != init_id do
    PN.notify({"broadcast", "COMMENT", comment.id, "create_root_comment"},
      to: orb_init_id,
      notification: %{
        title: "#{comment.initiator.username} replied",
        body: comment.body,
      }, data: %{
        action_path: "/comland/comments/root/#{comment.id}"
      })
    :ok
  end
  defp notify_self(_comment), do: :ok
end
