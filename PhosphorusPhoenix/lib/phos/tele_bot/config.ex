defmodule Phos.TeleBot.Config do
  def load() do
    Registry.put_meta(Registry.ExGram, {Phos.TeleBot, :config}, config())
  end

  def get(key, default \\ "") do
    case Registry.meta(Registry.ExGram, {Phos.TeleBot, :config}) do
      {:ok, config} -> Keyword.get(config, key, default) |> eval()
      _ -> default
    end
    |> ensure_https(key)
  end

  defp eval({mod, func, args}) when is_atom(mod) and is_atom(func), do: apply(mod, func, args)
  defp eval(data), do: data

  defp ensure_https(data, :callback_url) do
    data
    |> URI.parse()
    |> Map.put(:scheme, "https")
    |> URI.to_string()
  end
  defp ensure_https(data, _key), do: data

  defp config() do
    Application.get_env(:phos, Phos.TeleBot, [])
  end
end
