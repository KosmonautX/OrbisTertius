defmodule Phos.ParamsValidator do
  def sanitize(module, sig_opts, params) do
    {opts, _} = sig_opts |> Macro.to_string() |> Code.eval_string()
    reducer(module, opts, params)
  end

  defp reducer(module, enumerable, data) do
    Enum.reduce(enumerable, %{}, fn param, acc ->
      case param do
        key when is_atom(key) or is_binary(key) -> getter(module, data, to_string(key), acc)
        {:rename, [key, to]} -> rename(module, data, to_string(key), to_string(to), acc)
        {key, nested} when is_list(nested) -> nested_reduce(module, nested, acc, key, data)
        _ -> acc
      end
    end)
  end

  defp nested_reduce(module, nested, acc, key, data) do
    case reducer(module, nested, data) do
      temp when is_map(temp) ->
        Map.keys(temp)
        |> length()
        |> case do
          0 -> acc
          _ -> Map.put(acc, to_string(key), temp)
        end
      temp -> Map.put(acc, to_string(key), temp)
    end
  end

  defp rename(module, data, key, to, acc) do
    data
    |> Map.get(key)
    |> get_default_data_from_caller(module, to, acc)
  end

  defp getter(module, data, key, acc) do
    data
    |> Map.get(key)
    |> get_default_data_from_caller(module, key, acc)
  end

  defp get_default_data_from_caller(data, module, key, acc) do
    eval_value(module, data, key)
    |> case do
      nil -> acc
      data -> Map.put(acc, key, data)
    end
  end

  defp eval_value(module, value, key) do
    try do
      module.parse_params(key, value)
    rescue
      FunctionClauseError -> parse_params(key, value)
    end
  end

  defp parse_params(_key, data), do: data

  defmacro __using__(opts) do
    quote do
      def sanitize(params) do
        Phos.ParamsValidator.sanitize(__MODULE__, unquote(opts), params)
      end

      def parse_params(_key, data), do: data

      defoverridable parse_params: 2
    end
  end
end
