defmodule PhosWeb.Layouts do
  use PhosWeb, :html

  embed_templates "layouts/*"

  
  def user_menu(assigns)

  attr(:contents, :map, required: true)
  def meta_tags(assigns) do
    ~H"""
    <meta :for={{name, value} <- parse_contents(@contents)} name={name} content={value} />
    """
  end

  defp parse_contents(contents) do
    contents
    |> Enum.map(&define_name/1)
    |> List.flatten()
    |> Enum.into(%{})
  end

  defp define_name({k, v}) when is_map(v), do: Enum.map(v, &define_name(&1, k))
  defp define_name(data), do: define_name(data, "og")
  defp define_name({k, v}, prefix), do: {"#{prefix}:#{k}", v}
end
