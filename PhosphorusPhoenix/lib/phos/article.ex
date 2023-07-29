defmodule Phos.Article do
  def build_article(title) do
    Phos.Action.search(title)
    |> case do
      [_ | _] = orbs -> build_article_from_orbs(title, orbs)
      _ -> {:error, "Orbs not found"}
    end
  end

  defp build_article_from_orbs(title, orbs) do
    articles = Enum.map(orbs, &request_to_openai/1)
    traits   = Enum.map(orbs, &(&1.traits)) |> List.flatten()
    medias   = Enum.map(orbs, fn o -> if o.media, do: Phos.Orbject.S3.get!("ORB", o.id, "public/banner/lossy") end)
    [opening, closing] = intro_and_closing_title(title)

    %{
      articles: Task.await_many(articles),
      traits: Enum.uniq(traits),
      title: title,
      related_orbs: Enum.map(orbs, &(&1.id)),
    }
  end

  defp request_to_openai(%{title: title}) do
    Task.async(fn ->
      Phos.Models.OpenAI.chat(title)
      |> parse_article_body()
    end)
  end

  defp parse_article_body(%{status: status, body: body}) when status == 200 do
    Enum.map(body, fn data ->
      data
      |> Map.get("choices")
      |> List.first()
      |> Map.get("delta")
      |> Map.get("content")
    end)
  end
  defp parse_article_body(_), do: ""

  defp intro_and_closing_title(title) do
    [
      "Write me a short introduction paragraph of no more than 2 sentences for the article titled",
      "Write me a short closing paragraph of no more than 2 sentences for the article titled"
    ] |> Enum.map(fn data ->
      request_to_openai("#{data} #{title}")
    end)
    |> Task.await_many()
  end
end
