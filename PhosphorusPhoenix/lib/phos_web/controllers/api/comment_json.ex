defmodule PhosWeb.Api.CommentJSON do

  def index(%{comments: comments}) do
    %{data: Enum.map(comments, &show(%{comment: &1}))}
  end

  def show(%{comment: comment}) do
    Enum.take(comment, [:id, :active, :child_count, :body, :parent_id, :orb_id])
    |> Map.merge(%{
      path: to_string(comment.path),
      relationships: PhosWeb.Util.Viewer.relationship_reducer(comment),
      creationtime: parse_time(comment.inserted_at),
      mutationtime: parse_time(comment.updated_at)
    })
  end

  defp parse_time(time), do: DateTime.from_naive!(time, "Etc/UTC") |> DateTeim.to_unix()
end
