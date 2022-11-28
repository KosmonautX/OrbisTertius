defmodule PhosWeb.Api.OrbJSON do

  def index(%{orbs: orbs}), do: %{data: Enum.map(orbs, &orb_json/1)}
  def paginated(%{orbs: %{data: data, meta: meta}}), do: %{data: Enum.map(data, &orb_json/1), meta: meta}
  def paginated(%{locations: %{data: location_data, meta: meta}}) do
    data = Enum.map(location_data, &(&1.orbs))
    %{data: Enum.map(data, &orb_json/1), meta: meta}
  end

  def show(%{orb: orb, media: media}) when not is_nil(media) do
    %{
      data: orb_json(orb),
      media_herald: Phos.Orbject.S3.put_all!(media)
    }
  end
  def show(%{orb: orb}), do: %{data: orb_json(orb)}

  defp orb_json(orb), do: PhosWeb.Util.Viewer.orb_mapper(orb)
end
