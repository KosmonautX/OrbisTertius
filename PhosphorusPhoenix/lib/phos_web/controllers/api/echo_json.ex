defmodule PhosWeb.API.EchoJSON do

  def paginated(%{reveries: %{data: [], meta: meta}}), do: %{data: [], meta: meta}

  def paginated(%{reveries: %{data: data, meta: meta}}), do: %{data: Enum.map(data, &reverie_json/1), meta: meta}

  def show(%{memory: memory, media: media}) when not is_nil(media) do
    %{
      data: memory_json(memory),
      media_herald: Phos.Orbject.S3.put_all!(media)
    }
  end

  def show(%{memory: memory}), do: %{data: memory_json(memory)}

  defp reverie_json(reverie) do
    PhosWeb.Util.Viewer.reverie_mapper(reverie)
  end

  defp memory_json(memory) do
    PhosWeb.Util.Viewer.memory_mapper(memory)
  end
end
