defmodule PhosWeb.CommentLive.IndexComponent do
  use PhosWeb, :live_component

  alias Phoenix.LiveView.JS

  def mount(_params, _session, socket), do: {:ok, socket}

  # @impl true
  # def handle_params(%{"id" => id, "cid" => cid} = params, _url, socket) do
  #   # IO.inspect(socket)
  #   {:noreply, socket
  #     |> assign(:orb, Action.get_orb!(id))
  #     |> assign(:comments, Comments.get_root_comments_by_orb(id))}
  # end

  # defp apply_action(socket, :reply, %{"cid" => cid}) do
  #   socket
  #   |> assign(:changeset, Comments.change_comment(%Comments.Comment{}))
  #   |> assign(:comment, Comments.get_comment!(cid))
  #   |> assign(:page_title, "Reply")
  # end

  def xcard(assigns) do
    ~H"""
    <div class="comment" id={"comment-#{elem(@comment, 1).id}"}>
      <a class="avatar">
        <img src={ Phos.Orbject.S3.get!("USR", elem(@comment, 1).initiator_id, "150x150") }>
      </a>
      <div class="content">
        <a class="author"><%= elem(@comment, 1).initiator.username %></a>
        <div class="metadata">
          <span class="date"><%= elem(@comment, 1).inserted_at %></span>
        </div>
        <div class="text">
          <p>CID: <%= elem(@comment, 1).id%></p>
          <p :if={elem(@comment, 1).active}><%= elem(@comment, 1).body %></p>
          <div if={not elem(@comment, 1).active}>
            <p><i>-- Comment deleted --</i></p>
            <details>
              <summary>view deleted comment</summary>
              <%= elem(@comment, 1).body %>
            </details>
          </div>
        </div>
        <div class="actions">
          <.link patch={ ~p"/orb/#{@orb.id}/reply/#{elem(@comment, 1).id}" }>Reply</.link>
          <.link :if={elem(@comment, 1).active } patch={ ~p"/orb/#{@orb.id}/edit/#{elem(@comment, 1).id}" }>Edit</.link>
          <.link :if={elem(@comment, 1).active } phx-click={JS.push("delete", value: %{id: elem(@comment, 1).id})} data-confirm="Are you sure?">Delete</.link>

          <div :if={elem(@comment, 1).child_count > 0}>
            <div id={"showreply-#{elem(@comment, 1).id}"} style="display: none">
              <.link href="#" phx-click={JS.push("toggle_more_replies") |> JS.toggle(to: "#morereplies-#{elem(@comment, 1).id}") |> JS.toggle(to: "#morereplies-#{elem(@comment, 1).id}") |> JS.toggle(to: "#showreply-#{elem(@comment, 1).id}") |> JS.toggle(to: "#hidereply-#{elem(@comment, 1).id}")}, phx-value-initmorecomments="false", phx-value-orb={@orb.id}, phx-value-path={to_string(elem(@comment, 1).path)}>Show replies [<%= elem(@comment, 1).child_count %>]</.link>
            </div>
            <div id={"hidereply-#{elem(@comment, 1).id}"} style="display: none">
              <.link href="#" phx-click={JS.push("toggle_more_replies") |> JS.toggle(to: "#morereplies-#{elem(@comment, 1).id}") |> JS.toggle(to: "#morereplies-#{elem(@comment, 1).id}") |> JS.toggle(to: "#hidereply-#{elem(@comment, 1).id}") |> JS.toggle(to: "#showreply-#{elem(@comment, 1).id}")}, phx-value-initmorecomments="false", phx-value-orb={@orb.id}, phx-value-path={to_string(elem(@comment, 1).path)}>Hide replies  [<%= elem(@comment, 1).child_count %>]</.link>
            </div>
            <div id={"initshowreply-#{elem(@comment, 1).id}"} >
              <.link href="#" phx-click={JS.push("toggle_more_replies") |> JS.toggle(to: "#initshowreply-#{elem(@comment, 1).id}") |> JS.toggle(to: "#hidereply-#{elem(@comment, 1).id}")}, phx-value-initmorecomments="true", phx-value-orb={@orb.id}, phx-value-path={to_string(elem(@comment, 1).path)}>Show replies [<%= elem(@comment, 1).child_count %>]</.link>
            </div>
          </div>
        </div>
      </div>

      <div class="comments" id={"morereplies-#{elem(@comment, 1).id}"}>
        <%= for nestedcomment <- filter_child_comments_chrono(@comments, @comment) do %>
          <.xcard comment={nestedcomment} comments={@comments} changeset={@changeset} orb={@orb} current_user={@current_user} socket={@socket} live_action={@live_action}/>
        <% end %>
      <%# <.live_component module={PhosWeb.CommentLive.NestedComponent} id={"nested-#{elem(@comment,1).id}"} comment={@comment} changeset={@changeset} orb={@orb} comments={@comments} current_user={@current_user} socket={@socket} live_action={@live_action} /> %>
      </div>
    </div>
    """
  end

  def sort_comments_chrono(comments) do
    Enum.sort_by(comments, &elem(&1, 1).inserted_at, :desc)
  end

  def filter_root_comments_chrono(comments) do
    comments
    |> Enum.filter(&match?({{_}, _}, &1))
    |> sort_comments_chrono()
  end

  def filter_child_comments_chrono(comments, comment) do
    comments
    |> Enum.filter(fn i -> elem(i, 1).parent_id == elem(comment, 1).id end)
    |> sort_comments_chrono()
  end
end
