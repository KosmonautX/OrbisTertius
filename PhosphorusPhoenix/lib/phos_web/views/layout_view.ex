defmodule PhosWeb.LayoutView do
  use PhosWeb, :view
  # import Phoenix.Component

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def meta_tags(assigns) do
    ~H"""
    <meta :for={{name, value} <- parse_contents(@contents)} name={name} content={value} />
    """
  end

  defp parse_contents(contents) when is_map(contents) do
    contents
    |> Enum.map(&define_name/1)
    |> List.flatten()
    |> Enum.into(%{})
  end
  defp parse_contents(_contents), do: %{}

  defp define_name({k, v}) when is_map(v), do: Enum.map(v, &define_name(&1, k))
  defp define_name(data), do: define_name(data, "og")
  defp define_name({k, v}, prefix), do: {"#{prefix}:#{k}", v}
end
