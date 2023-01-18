defmodule PhosWeb.API.CommentJSON do

  def index(%{comments: comments}) do
    %{data: Enum.map(comments, &comment_json/1)}
  end

  def paginated(%{comments: %{data: data, meta: meta}}), do: %{data: Enum.map(data, &comment_json/1), meta: meta}

  def show(%{comment: comment}), do: %{data: comment_json(comment)}

  defp comment_json(comment) do
    Map.take(comment, [:id, :active, :child_count, :body, :parent_id, :orb_id])
    |> Map.merge(%{
      path: to_string(comment.path),
      relationships: PhosWeb.Util.Viewer.relationship_reducer(comment),
      creationtime: parse_time(comment.inserted_at),
      mutationtime: parse_time(comment.updated_at)
    })
  end

  defp parse_time(time), do: DateTime.from_naive!(time, "Etc/UTC") |> DateTime.to_unix()
end
