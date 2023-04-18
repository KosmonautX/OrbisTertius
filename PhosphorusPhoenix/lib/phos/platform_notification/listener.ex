defmodule Phos.PlatformNotification.Listener do
  use GenServer

  require Logger

  alias Phos.PlatformNotification, as: PN

  @channel "table_changes"

  def start_link(channel), do: GenServer.start_link(__MODULE__, channel, name: __MODULE__)

  @impl true
  def init(_channel) do
    :logger.info(%{
      label: {Phos.PlatformNotification.Listener, :init},
      report: %{
        module: __MODULE__,
        action: "Starting channel specified subscription",
        channel: @channel,
      }
    }, %{
      domain: [:phos],
      error_logger: %{tag: :info_msg}
    })

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
    PN.notify({"broadcast", "COM", comment.id, "reply_com"},
      memory: %{user_source_id: init_id, com_subject_id: comment.id, orb_subject_id: comment.orb_id},
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

  defp notify_initiator(%{initiator_id: init_id, orb: %{initiator_id: orb_init_id} = orb, parent: %{initiator_id: parent_init_id}} = comment)
    when orb_init_id not in [init_id, parent_init_id] do
    PN.notify({"broadcast", "COM", comment.id, "reply_orb_children"},
      memory: %{user_source_id: init_id, com_subject_id: comment.id, orb_subject_id: orb.id},
      to: orb_init_id,
      notification: %{
        title: "#{comment.initiator.username} replied to a comment within your post",
        body: comment.body,
      }, data: %{
        action_path: "/comland/comments/children/#{comment.id}"
      })
    comment
  end
  defp notify_initiator(comment), do: comment

  defp notify_self(%{orb: %{initiator_id: orb_init_id} = orb, initiator_id: init_id, parent_id: nil} = comment) when orb_init_id != init_id do
    PN.notify({"broadcast", "COM", comment.id, "reply_orb_root"},
      memory: %{user_source_id: init_id, com_subject_id: comment.id, orb_subject_id: orb.id},
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
