defmodule Phos.Article do
  defstruct [:contents, :related_orbs, :opening, :closing, :traits, :title]

  def build_article(title) do
    Phos.Action.search(title)
    |> case do
      [_ | _] = orbs -> build_article_from_orbs(title, orbs)
      _ -> {:error, "Orbs not found"}
    end
  end

  defp build_article_from_orbs(title, orbs) do
    contents = Enum.map(orbs, fn d -> Task.async(fn -> get_orb_information(d) end) end)
    [opening, closing] = intro_and_closing_title(title)

    %__MODULE__{
      contents: Task.await_many(contents, 10_000),
      traits: Enum.map(orbs, &(&1.traits)) |> List.flatten() |> Enum.uniq(),
      title: title,
      related_orbs: Enum.map(orbs, &(&1.id)),
      opening: opening,
      closing: closing,
    }
  end

  defp get_orb_information(orb) do
    paragraph = request_to_openai("Write me paragraph more than 2 sentences with topic #{orb.title}")

    data = %{
      comments: get_orb_comments(orb.id),
      paragraph: Task.await(paragraph, 10_000),
    }

    case orb.media do
      true -> Map.put(data, :media, Phos.Orbject.S3.get!("ORB", orb.id, "public/banner/lossy"))
      _ -> Map.put(data, :media, nil)
    end
  end

  defp get_orb_comments(orb_id) do
    case Phos.Comments.get_root_comments_by_orb(orb_id, 1) do
      %{data: [_ | _] = data} -> data
      _ -> []
    end
  end

  defp request_to_openai(title) do
    Task.async(fn ->
      Phos.Models.OpenAI.chat(title)
      |> parse_openai_body()
    end)
  end

  defp parse_openai_body(%{status: status, body: body}) when status == 200 do
    Enum.map(body, fn data ->
      data
      |> Map.get("choices")
      |> List.first()
      |> Map.get("delta")
      |> Map.get("content")
    end)
    |> Enum.join()
  end
  defp parse_openai_body(_), do: ""

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
