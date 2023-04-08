defmodule PhosWeb.Layouts do
  use PhosWeb, :html

  embed_templates "layouts/*"


  # links
  # redirect inward and outward
  # author information

  def user_menu(assigns)

  attr(:contents, :map, required: true)
  def meta_tags(assigns) do
    ~H"""
    <meta :for={{name, value} <- parse_contents(@contents)} property={name} content={value} />
    """
  end

  defp parse_contents(contents) when is_map(contents) do
    contents
    |> Enum.map(&define_name/1)
    |> List.flatten()
    |> Enum.into(%{})
  end
  defp parse_contents(_contents), do: %{}

  defp define_name({k, %Phos.Users.User{username: name}}) do
    {k, name}
  end
  defp define_name({k, v}) when is_map(v) do
    Enum.map(v, &define_name(&1, k))
  end
  defp define_name(data), do: define_name(data, "og")
  defp define_name({k, v}, prefix), do: {"#{prefix}:#{k}", v}
end
