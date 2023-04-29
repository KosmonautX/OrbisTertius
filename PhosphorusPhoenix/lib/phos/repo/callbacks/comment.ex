defmodule Phos.Repo.Callbacks.Comment do
  use Phos.Repo.Callbacks

  alias Phos.PlatformNotification, as: PN

  def callback(:insert, data) do
    data
    |> Phos.Repo.preload([:parent, :orb, :initiator])
    |> notify_parent_element()
    |> notify_initiator()
    |> notify_self()
  end
  def callback(_opertaion, data), do: data

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
