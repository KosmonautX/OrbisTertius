defmodule PhosWeb.API.OrbJSON do

  def index(%{orbs: orbs}), do: %{data: Enum.map(orbs, &orb_json/1)}
  def paginated(%{orbs: %{data: data, meta: meta}}), do: %{data: Enum.map(data, &orb_json/1), meta: meta}
  def paginated(%{locations: %{data: location_data, meta: meta}}) do
    data = Enum.map(location_data, &(&1.orbs))
    %{data: Enum.map(data, &orb_json/1), meta: meta}
  end

  def show(%{orb: %{blorbs: [%Phos.Action.Blorb{} | _] = blorbs} = orb, media: media}) when not is_nil(media) do
    %{
      data: orb_json(orb),
      media_herald: Phos.Orbject.S3.put_all!(media_blorber(media, blorbs))
    }
  end

  def show(%{orb: orb, media: media}) when not is_nil(media) do
    %{
      data: orb_json(orb),
      media_herald: Phos.Orbject.S3.put_all!(media)
    }
  end
  def show(%{orb: orb}), do: %{data: orb_json(orb)}

  # tie the media_ids based on count tags
  defp media_blorber(media, blorbs) do
    b = blorbs |> Enum.map(fn %{type: :img, character: %{count: count}} = blorb -> {count, blorb}
      _ -> {nil, nil}
    end
    )
    |> Enum.into(%{})

    blorbed_media = media.media |>
      Enum.map(
        fn %{essence: "blorb", count: count} = media ->
          case b[count] do
            %{id: id} -> %{media | essence_id: id}
            _ -> nil
          end
          media -> media
        end)
        |> Enum.reject(&is_nil(&1))
    %{media | media: blorbed_media}
  end

  defp orb_json(orb), do: PhosWeb.Util.Viewer.orb_mapper(orb)
end
