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

  def process_request_body(body) when is_map(body)  do
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

  defp auth_method() do
    auth_type = Keyword.get(config(), :authorization_type, "Bearer") |> String.trim()
    auth_token = Keyword.get(config(), :token, "")
    "#{auth_type} #{auth_token}"
  end

  defp notion_version, do: Keyword.get(config(), :version) ||  "2022-02-22"
  defp database, do: Keyword.get(config(), :database, "") |> eval_value()
  defp notification_database, do: Keyword.get(config(), :notification_database, "") |> eval_value()
  defp config(), do: Application.get_env(:phos, __MODULE__, [])

  defp eval_value({module, func, value}), do: apply(module, func, [value])
  defp eval_value(value), do: value
end
