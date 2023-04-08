defmodule PhosWeb.Util.Routing do

  @routes PhosWeb.Router.__routes__()
  |> Enum.map(fn r -> r.path end)

  def match(path) do
    Enum.find_value(@routes, nil, &match(&1, path))
  end

  defp match(route, path) when is_binary(route) do
    pattern = String.replace(route, ~r/:(\w+)/, ~S"(?<\g{1}>[\w-]+)")
    regex = ~r/^#{pattern}$/

    case Regex.named_captures(regex, path) do
      nil -> nil
      map -> {route, map}
    end
  end

end
