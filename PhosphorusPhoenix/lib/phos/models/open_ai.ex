defmodule Phos.Models.OpenAI do
  def chat(prompt) do
    stream("#{base_url()}/chat/completions", %{
      model: "gpt-3.5-turbo",
      messages: [%{role: "user", content: prompt}],
      stream: true,
    }, fn data -> data end)
  end

  def completions(prompt, opts \\ []) do
    max_tokens = Keyword.get(opts, :max_tokens, 100)

    stream("#{base_url()}/completions", %{
      model: "text-davinci-003",
      prompt: prompt,
      max_tokens: max_tokens,
      n: 2,
      stream: true,
    }, fn data -> data end)
  end

  def stream(url, data, context) do
    fun = fn(req, finch_req, name, opts) ->
      callback = fn
        {:status, status}, response -> %{response | status: status}
        {:headers, headers}, response -> %{response | headers: headers}
        {:data, data}, response -> parse_body(response, data, context)
      end

      case Finch.stream(finch_req, name, Req.Response.new(), callback, opts) do
        {:ok, response} -> {req, response}
        {:error, exception} -> {req, exception}
      end
    end

    Req.post!(url, json: data,
    auth: {:bearer, token()},
    finch_request: fun)
  end

  defp parse_body(response, data, context) do
    body =
      data
      |> String.split("data: ")
      |> Enum.map(fn str ->
        str
        |> String.trim()
        |> decode_body(context)
      end)
      |> Enum.filter(fn d -> d != :ok end)

    old_body = case response.body do
      "" -> []
      d -> d
    end

    %{response | body: old_body ++ body}
  end

  defp base_url, do: Map.get(config(), :base_url, "https://api.openai.com/v1")
  defp token, do: Map.get(config(), :token, "") |> eval()
  defp config, do: Application.get_env(:phos, __MODULE__, []) |> Enum.into(%{})

  defp eval(str) when is_bitstring(str), do: str
  defp eval({module, fun, opts}) when is_bitstring(opts), do: eval({module, fun, [opts]})
  defp eval({module, fun, opts}), do: apply(module, fun, opts)

  defp decode_body("", _), do: :ok
  defp decode_body("[DONE]", _), do: :ok
  defp decode_body(json, cb), do: cb.(Jason.decode!(json))
end