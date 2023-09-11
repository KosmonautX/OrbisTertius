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
      contents: Task.await_many(contents, 100_000),
      traits: Enum.map(orbs, &(&1.traits)) |> List.flatten() |> Enum.uniq(),
      title: title,
      related_orbs: Enum.map(orbs, &(&1.id)),
      opening: opening,
      closing: closing,
    }
  end

  ## build article context needs to change <> syntax tree and the pass to external in one go not 1 one by 1

  defp get_orb_information(orb) do
    paragraph = request_to_openai("Write me paragraph more than 2 sentences with topic #{orb.title}")

    data = %{
      comments: get_orb_comments(orb.id),
      paragraph: Task.await(paragraph, 30_000),
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
    |> Task.await_many(30_000)
  end

  def orb_notion_list do
    Phos.External.Notion.orbs()
    |> case do
      [_ | _] = data -> Enum.map(data, &process_orb/1)
      _ -> []
    end
  end

  defp process_orb(orb) do
    Map.get(orb, "properties")
    |> Enum.map(fn {key, val} ->
      {String.downcase(key), Phos.External.Notion.find_value(val)}
    end)
    |> Enum.into(%{})
  end

  def article_tits do
    Phos.External.Notion.article_tits()
    |> case do
      [_ | _] = data -> Enum.map(data, &process_article_tit/1)
      _ -> []
    end
  end

  defp process_article_tit(%{"id" => id} = article) do
    data = 
      Map.get(article, "properties")
      |> Enum.map(fn {key, val} ->
        k = String.downcase(key) |> String.replace(" ", "_") |> String.replace("&", "_and_") |> String.to_atom()
        {k, Phos.External.Notion.find_value(val)}
      end)
      |> Enum.into(%{})
      |> Map.put(:id, id)

    struct(__MODULE__.Scoop, data)
  end

  def article_blocks(page_id) do
    Phos.External.Notion.article_blocks(page_id)
    |> case do
      data when is_map(data) -> process_article_blocks(data)
      _ -> %{}
    end
  end

  defp process_article_blocks(%{"has_children" => true, "id" => id} = data) do
    Phos.External.Notion.article_block_children(id)
    |> case do
      %{"results" => [_ | _] = data} -> Enum.map(data, &Phos.External.Notion.block_value/1) |> Enum.reject(&Kernel.is_map/1) |> Enum.join()
      _ -> data
    end
  end
  defp process_article_blocks(data), do: data

  def search_article_by_title(title) do
    Phos.External.Notion.search_article(title)
    |> case do
      %{"results" => [_ | _] = data} -> Enum.map(data, &process_article_tit/1)
      _ -> []
    end
  end

  def article_orbs(article_id) do
    query = %{
      "filter" => %{
        "property" => "article_tits",
        "relation" => %{
          "contains" => article_id
        }
      }
    }

    Phos.External.Notion.orbs(query)
    |> Enum.map(fn data ->
      process_orb(data)
      |> Map.get("orb")
      |> String.split("/")
      |> List.last()
      |> String.split("?")
      |> List.first()
    end)
  end

  def create_scoop(title, orbs) do
    # 1. create page
    Phos.External.Notion.create_article(%{
      "title" => %{type: "title", value: title},
      "tags" => %{type: "multi_select", value: ["GPT Generated", "Automated"]},
    })
    |> append_scoop(orbs)
    # 2. append_scoop
  end

  def append_scoop(page_id, orbs) when is_bitstring(page_id) do
    # 1. create orbeez page
    Enum.map(orbs, fn o ->
      Phos.External.Notion.create_orb_entry(%{
        "place" => %{type: "title", value: o.payload.where},
        "Details" => %{type: "rich_text", value: o.title},
        "user" => %{type: "url", value: Phoenix.VerifiedRoutes.unverified_url(PhosWeb.Endpoint, "/user/#{o.initiator.username}")},
        "link" => %{type: "url", value: Phoenix.VerifiedRoutes.unverified_url(PhosWeb.Endpoint, "/orbs/#{o.id}")},
        "article_tits" => %{type: "relation", value: page_id},
        "type" => %{type: "select", value: "New"},
      })
    end)
    |> Enum.reject(fn map -> Map.get(map, "object") == "error" end)
    |> case do
      [_ | _] = _value -> do_append_scoop(page_id, orbs)
      _ -> {:error, "cannot create orb page"}
    end
    # 2. append to article tits
  end
  def append_scoop(response, orbs), do: Map.get(response, "id") |> append_scoop(orbs)

  def do_append_scoop(_page_id, [] = _orbs), do: :ok
  def do_append_scoop(page_id, [orb | tail] = _orbs) do
    bag = get_orb_information(orb) |> Map.put(:title, orb.title)

    ["heading_2", "paragraph", "image"]
    |> Enum.map(fn key ->
      data = Map.new() |> Map.put(key, find_value(bag, key))
      Phos.External.Notion.append_page(page_id, data)
    end)

    data = Map.new() |> Map.put("paragraph", find_value(bag, "comments"))
    Phos.External.Notion.append_page(page_id, data)

    do_append_scoop(page_id, tail)
  end

  defp find_value(data, "heading_2"), do: Map.get(data, :title)
  defp find_value(data, "paragraph"), do: Map.get(data, :paragraph)
  defp find_value(data, "comments"), do: Map.get(data, :comments) |> prepare_comments()
  defp find_value(data, "image"), do: Map.get(data, :media) |> prepare_media()

  defp prepare_media(nil), do: ""
  defp prepare_media(media), do: %{value: media}

  defp prepare_comments(comments) do
    Enum.map(comments, fn c ->
      [
        %{value: c.initiator.username, link: "/user/#{c.initiator.username}"},
        %{value: " said #{c.body}"},

      ]
    end) |> List.flatten()
  end
end
