defmodule PhosWeb.CommentLive.IndexComponent do
  use PhosWeb, :live_component
  def mount(_params, _session, socket), do: {:ok, socket}
end
