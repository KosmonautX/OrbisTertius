defmodule PhosWeb.API.FriendView do
  use PhosWeb, :view

  def render("index.json", %{friends: friends}) do
    %{data: render_many(friends, __MODULE__, "show.json")}
  end

  def render("paginated.json", %{friends: friends}) do
    %{data: render_many(friends.data, __MODULE__, "show.json"), meta: friends.meta}
  end

  def render("show.json", %{friend: user}) do
    PhosWeb.Util.Viewer.user_mapper(user)
  end

  def render("relation.json", %{relation: relation}) do
    Map.take(relation, [:id, :state])
  end

  def render("relation_error.json", %{reason: reason}) when is_bitstring(reason) do
    %{
      state: "error",
      message: reason,
    }
  end

  def render("relation_error.json", %{reason: changeset}) do
    messages =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)
      |> Enum.map(fn {key, msgs} ->
        Enum.map(msgs, fn m -> "#{key} #{m}" end)
      end)
      |> List.flatten()

    %{
      state: "error",
      messages: messages,
    }
  end
end
