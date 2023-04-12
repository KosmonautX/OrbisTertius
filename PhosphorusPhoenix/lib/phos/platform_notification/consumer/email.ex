defmodule Phos.PlatformNotification.Consumer.Email do
  use Phos.PlatformNotification.Specification

  @impl true
  def send(%{spec: spec, template_id: template_id} = store) do
    notifier = Phos.Users.UserNotifier
    fun = :"deliver_#{template_id}_instructions"
    url = get_in(spec, [Access.key("options", %{}), Access.key("url")])

    case function_exported?(notifier, fun, 2) do
      true -> apply(Phos.Users.UserNotifier, fun, [store.recepient, url])
      _ -> {:error, "Function not defined yet."}
    end
  end
end
