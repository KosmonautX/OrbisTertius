defmodule Phos.TeleBot.Config do
  @channel_id "@emmausdev2"

  def load() do
    Registry.put_meta(Registry.ExGram, {Phos.TeleBot.Core, :config}, config())
    Registry.put_meta(Registry.ExGram, :guest_splash, "https://imgur.com/a/Z2vphEX")
    Registry.put_meta(Registry.ExGram, :user_splash, "https://imgur.com/a/GgdHYqy")
    Registry.put_meta(Registry.ExGram, :faq_splash, "https://imgur.com/a/hkFJfOo")
  end

  def get(key, default \\ "") do
    case Registry.meta(Registry.ExGram, {Phos.TeleBot.Core, :config}) do
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
    Application.get_env(:phos, Phos.TeleBot.Core, [])
  end
end
