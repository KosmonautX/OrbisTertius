defmodule Phos.External.Sector do
  use Retry

  def get do
    case do_get_sector() do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} -> Phoenix.json_library().decode!(body)
      {:error, err} -> raise RuntimeError, HTTPoison.Error.message(err)
    end
  end

  defp do_get_sector do
    retry with: constant_backoff(100) |> Stream.take(5) do
      HTTPoison.get(sector_url())
    after
      {:ok, _resp} = response -> response
    else
      err -> err
    end
  end

  defp sector_url() do
    case Keyword.get(config(), :url) do
      url when is_binary(url) -> url
      _ -> raise RuntimeError, "Sector URL not found."
    end
  end

  defp config(), do: Application.get_env(:phos, __MODULE__, [])
end