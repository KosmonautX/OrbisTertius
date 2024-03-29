defmodule PhosWeb.CommentLive.IndexComponent do
  use PhosWeb, :live_component
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full bg-white px-2 mt-2 lg:mt-0 lg:rounded-b-3xl dark:bg-gray-900 lg:dark:bg-gray-800 font-poppins">
      <h2 :if={length(@root_comments) > 1} class="text-gray-900 font-normal lg:text-base text-sm dark:text-white px-2 md:px-4 lg:hidden block">
        commented by <strong><%= elem(hd(@root_comments), 1).initiator.username %> </strong> and <strong>others</strong>
      </h2>

      <div class="hidden lg:block">
        <.live_component
          module={PhosWeb.CommentLive.FormComponent}
          changeset={@changeset}
          current_user={@current_user}
          orb={@orb}
          id={"create-root-comment-desktop-#{@orb.id}"}
          target={nil}
          action={:new}
        />
      </div>

      <div class="ui threaded comments overflow-y-auto h-full lg:rounded-b-3xl mb-14 lg:mb-0">
        <.live_component
          :for={comment <- @root_comments}
          module={PhosWeb.CommentLive.ShowComponent}
          comment={comment}
          comments={@comments}
          changeset={@changeset}
          id={"comment-#{elem(comment, 1).id}"}
          orb={@orb}
          current_user={@current_user}
          socket={@socket}
          reply_comment={@reply_comment}
          edit_comment={@edit_comment}
          phx-target={"#comment-#{elem(comment, 1).id}"}
        />
      </div>
    </div>
    """
  end
end
