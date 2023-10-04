defmodule PhosWeb.API.BlorbJSON do

  def index(%{blorbs: blorbs}), do: %{data: Enum.map(blorbs, &blorb_json/1)}
  def paginated(%{blorbs: %{data: data, meta: meta}}), do: %{data: Enum.map(data, &blorb_json/1), meta: meta}
  def paginated(%{locations: %{data: location_data, meta: meta}}) do
    data = Enum.map(location_data, &(&1.blorbs))
    %{data: Enum.map(data, &blorb_json/1), meta: meta}
  end

  def show(%{blorb: %{blblorbs: [%Phos.Action.Blblorb{} | _] = blblorbs} = blorb, media: media}) when not is_nil(media) do
    %{
      data: blorb_json(blorb),
      media_herald: Phos.Blorbject.S3.put_all!(media_blblorber(media, blblorbs))
    }
  end

  def show(%{blorb: blorb, media: media}) when not is_nil(media) do
    %{
      data: blorb_json(blorb),
      media_herald: Phos.Blorbject.S3.put_all!(media)
    }
  end
  def show(%{blorb: blorb}), do: %{data: blorb_json(blorb)}

  # tie the media_ids based on count tags
  defp media_blblorber(media, blblorbs) do
    b = blblorbs |> Enum.map(fn %{type: type, character: %{count: count}} = blblorb when type in [:vid, :img] -> {count, blblorb}
      _ -> {nil, nil}
    end
    )
    |> Enum.into(%{})

    blblorbed_media = media.media |>
      Enum.map(
        fn %{essence: "blblorb", count: count} = media ->
          case b[count] do
            %{id: id} -> %{media | essence_id: id}
            _ -> nil
          end
          media -> media
        end)
        |> Enum.reject(&is_nil(&1))
    %{media | media: blblorbed_media}
  end

  defp blorb_json(blorb), do: PhosWeb.Util.Viewer.blorb_mapper(blorb)
end
