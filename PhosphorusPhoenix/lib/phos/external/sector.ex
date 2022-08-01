defmodule Phos.External.Sector do
  def get do
    case HTTPoison.get(sector_url()) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} -> Phoenix.json_library().decode!(body)
      {:error, err} -> raise RuntimeError, HTTPoison.Error.message(err)
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
