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

  def render("paginated.json", %{relations: data, meta: meta}) do
    %{data: render_many(data, __MODULE__, "relation.json"), meta: meta}
  end



  def render("show.json", %{relation: relation}) do
    %{data: render_one(relation, __MODULE__, "relation.json")}
  end


  def render("relation.json", %{friend: relation}) do
    PhosWeb.Util.Viewer.user_relation_mapper(relation)
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
