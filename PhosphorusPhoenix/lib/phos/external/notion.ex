defmodule Phos.External.Notion do
  use HTTPoison.Base
  use Retry

  def today_post, do: DateTime.utc_now()
  |> DateTime.add(60 * 60 * 8) |> DateTime.to_date() |> date_post()

  def yesterday_post, do: DateTime.utc_now()
  |> DateTime.add(-60 * 60 * 16) |> DateTime.to_date() |> date_post()

  def platform_notification do
    query = %{}

    case do_get_notion_data(notification_database(), query) do
      {:ok, %HTTPoison.Response{body: body}} -> Map.get(body, "results", [])
      {:error, err} -> HTTPoison.Error.message(err)
    end
  end

  def update_platform_notification(page_id, data) do
    case do_update_notion_data(page_id, data) do
      {:ok, %HTTPoison.Response{body: body}} -> Map.get(body, "properties", %{})
      {:error, err} -> HTTPoison.Error.message(err)
    end
  end

  def orbs(query \\ %{}) do
    case do_get_notion_data(orb_database(), query) do
      {:ok, %HTTPoison.Response{body: body}} -> 
        Map.get(body, "results", [])
      {:error, err} -> HTTPoison.Error.message(err)
    end
  end

  def article_tits(query \\ %{}) do
    case do_get_notion_data(article_database(), query) do
      {:ok, %HTTPoison.Response{body: body}} -> Map.get(body, "results", [])
      {:error, err} -> HTTPoison.Error.message(err)
    end
  end

  def article_blocks(id) do
    case do_get_notion_block_data(id) do
      {:ok, %HTTPoison.Response{body: body}} -> body
      {:error, err} -> HTTPoison.Error.message(err)
    end
  end

  def article_block_children(id) do
    case do_get_notion_block_children(id) do
      {:ok, %HTTPoison.Response{body: body}} -> body
      {:error, err} -> HTTPoison.Error.message(err)
    end
  end

  def search_article(title) do
    data = %{
      "filter" => %{
        "property" => "title",
        "rich_text" => %{
          "contains" => title
        }
      },
      "sorts" => [%{"timestamp" => "last_edited_time", "direction" => "ascending"}]
    }
    case do_get_notion_data(article_database(), data) do
      {:ok, %HTTPoison.Response{body: body}} -> body
      {:error, err} -> HTTPoison.Error.message(err)
    end
  end

  def find_value(%{"content" => data}), do: data
  def find_value(%{"name" => data}), do: data
  def find_value(%{"type" => type} = data) do
    Map.get(data, type)
    |> find_value()
  end
  def find_value(%{"id" => data}), do: data
  def find_value([_ | _] = data), do: Enum.map(data, &find_value/1) |> Enum.join("\n")
  def find_value(data), do: data

  def date_post(date) do
    date_query = %{
      "filter" => %{
        "property" => "Posting date",
        "date" => %{
          "equals" => date
        }
      }
    }

    case do_get_notion_data(database(), date_query) do
      {:ok, %HTTPoison.Response{body: body}} -> Map.get(body, "results", [])
      {:error, err} -> HTTPoison.Error.message(err)
    end
  end

  defp do_get_notion_block_data(page_id) do
    retry with: constant_backoff(100) |> Stream.take(5) do
      get("/blocks/#{page_id}")
    after
      {:ok, _res} = response -> response
    else
      err -> err
    end
  end

  defp do_get_notion_block_children(page_id) do
    retry with: constant_backoff(100) |> Stream.take(5) do
      get("/blocks/#{page_id}/children")
    after
      {:ok, _res} = response -> response
    else
      err -> err
    end
  end

  defp do_create_page(database_id, properties) do
    retry with: constant_backoff(100) |> Stream.take(5) do
      post("/pages", %{
        parent: %{database_id: database_id},
        properties: properties
      })
    after
      {:ok, _res} = response -> response
    else
      err -> err
    end
  end

  defp do_update_notion_data(database, query) do
    retry with: constant_backoff(100) |> Stream.take(5) do
      patch("/pages/#{database}", query)
    after
      {:ok, _res} = response -> response
    else
      err -> err
    end
  end

  defp do_get_notion_data(database, query) do
    retry with: constant_backoff(100) |> Stream.take(5) do
      post("/databases/#{database}/query", query)
    after
      {:ok, _res} = response -> response
    else
      err -> err
    end
  end

  def process_request_url(url) do
    "https://api.notion.com/v1" <> url
  end

  def process_request_body(body) when is_bitstring(body), do: body
  def process_request_body(body) when is_map(body) do
    Phoenix.json_library().encode!(body)
  end

  def process_response_body(body) do
    body
    |> Phoenix.json_library().decode!()
  end

  def process_request_headers(headers) do
    Keyword.put_new(headers, :authorization, auth_method())
    |> Keyword.put_new(:"content-type", "application/json")
    |> Keyword.put_new(:"notion-version", notion_version())
  end

  def block_value(%{"type" => "paragraph"} = data), do: find_text_and_annotation(data, "\n\n")
  def block_value(%{"type" => "text"} = data), do: find_text_and_annotation(data, " ")
  def block_value(%{"type" => "image", "image" => %{"caption" => caption}} = data) do
    url = find_value(data) |> Map.get("url")

    case caption do
      [_ | _] -> "\n![#{Enum.join(caption)}](#{url})\n\n"
      _ -> "\n![](#{url})\n\n"
    end
  end
  def block_value(%{"type" => "heading_" <> number} = data) do
    text = find_text_and_annotation(data, " ")
    num = String.to_integer(number)
    level = Enum.map(1..num, fn _ -> "#" end) |> Enum.join()

    "\n#{level} #{text}\n"
  end
  def block_value(%{"type" => "callout", "has_children" => false} = data), do: find_text_and_annotation(data, " ")
  def block_value(%{"type" => "callout", "id" => id} = data) do
    text = find_text_and_annotation(data, " ")
    case do_get_notion_block_children(id) do
      {:ok, %HTTPoison.Response{body: %{"results" => [_ | _] = data}}} ->
        final_text = 
          [text | Enum.map(data, &block_value/1)]
          |> Enum.join("\n")
        "> #{final_text}\n\n"
      _ -> text
    end
  end
  def block_value(%{"type" => _type} = data) do
    case find_value(data) do
      [] -> ""
      [_|_] = value -> Enum.join(value, "\n")
      %{"title" => title} -> title
      value -> find_text_and_annotation(value, " ")
    end
  end

  defp find_text_and_annotation(data, joiner) do
    case find_value(data) do
      %{"rich_text" => []} -> "\n"
      %{"rich_text" => [_|_] = value} ->
        Enum.map(value, fn v ->
          text = find_value(v)
          annotation = find_annotation(v)
          "#{annotation}#{text}#{String.reverse(annotation)}"
        end)
        |> Enum.join(joiner)
      val -> val
    end
  end

  defp find_annotation(%{"annotations" => ann}), do: Enum.map(ann, &find_annotation/1) |> Enum.join()
  defp find_annotation({"code", true}), do: "`"
  defp find_annotation({"bold", true}), do: "**"
  defp find_annotation({"italic", true}), do: "**"
  defp find_annotation({"strikethrough", true}), do: "~~"
  defp find_annotation(_data), do: ""

  def create_orb_entry(data) do
    case do_create_page(orb_database(), data) do
      {:ok, %HTTPoison.Response{body: body}} -> body
      {:error, err} -> HTTPoison.Error.message(err)
    end
  end

  def create_article(data) do
    case do_create_page(article_database(), to_notion_page_properties(data)) do
      {:ok, %HTTPoison.Response{body: body}} -> body
      {:error, err} -> HTTPoison.Error.message(err)
    end
  end

  defp auth_method() do
    auth_type = Keyword.get(config(), :authorization_type, "Bearer") |> String.trim()
    auth_token = Keyword.get(config(), :token, "")
    "#{auth_type} #{auth_token}"
  end

  defp to_notion_page_properties(data) do
    Enum.map(data, fn {k, v} ->
      {k, notion_page_definition(v)}
    end)
    |> Enum.into(%{})
  end

  defp notion_page_definition(%{type: type, value: value}) when type == "number" do
    Map.new()
    |> Map.put(type, value)
  end

  defp notion_page_definition(%{type: type, value: value}) when type == "select" do
    Map.new()
    |> Map.put(type, %{"name" => value})
  end

  defp notion_page_definition(%{type: type, value: value}) when type == "date" do
    Map.new()
    |> Map.put(type, %{"start" => value})
  end

  defp notion_page_definition(%{type: type, value: value}) when type == "people" do
    data = case value do
      nil -> %{"object" => "user", "bot" => %{}}
      _ -> %{"object" => "user", "id" => value}
    end
    Map.new()
    |> Map.put(type, [data])
  end

  defp notion_page_definition(%{type: type, value: value}) when type == "files" do
    Map.new()
    |> Map.put(type, [%{"name" => "", "external" => %{"url" => value}}])
  end

  defp notion_page_definition(%{type: type, value: value}) when type == "multi_select" do
    values = 
      case value do
        val when is_list(val) -> Enum.map(val, fn v -> %{"name" => v} end)
        _ -> [%{"name" => value}]
      end

    Map.new()
    |> Map.put(type, values)
  end

  defp notion_page_definition(%{type: type, value: value}) do
    Map.new()
    |> Map.put(type, [%{"text" => %{"content" => value}}])
  end
  defp notion_page_definition("number"), do: notion_page_definition(%{type: "number", value: 0})
  defp notion_page_definition(type), do: notion_page_definition(%{type: type, value: ""})

  defp notion_version, do: Keyword.get(config(), :version) ||  "2022-02-22"
  defp database, do: Keyword.get(config(), :database, "") |> eval_value()
  defp notification_database, do: Keyword.get(config(), :notification_database, "") |> eval_value()
  defp article_database, do: Keyword.get(config(), :article_database, "") |> eval_value()
  defp orb_database, do: Keyword.get(config(), :orb_database, "") |> eval_value()
  defp config(), do: Application.get_env(:phos, __MODULE__, [])

  defp eval_value({module, func, value}), do: apply(module, func, [value])
  defp eval_value(value), do: value
end
