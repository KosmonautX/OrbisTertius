defmodule PhosWeb.CommentLive.IndexComponent do
  use PhosWeb, :live_component

  import Phos.Comments, only: [filter_root_comments_chrono: 1]

  def mount(_params, _session, socket), do: {:ok, socket}
end
