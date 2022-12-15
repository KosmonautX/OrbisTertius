defmodule PhosWeb.API.EchoJSON do

  def index(%{echoes: echoes}) do
    %{data: Enum.map(echoes, &echo_json/1)}
  end

  def paginated(%{echoes: %{data: [], meta: meta}}), do: %{data: [], meta: meta}

  def paginated(%{echoes: %{data: data, meta: meta}}), do: %{data: Enum.map(data, &echo_json/1), meta: meta}

  def show(%{echo: echo}), do: %{data: echo_json(echo)}

  def show(%{echo: echo, media: media}) when not is_nil(media) do
    IO.inspect(media)
    %{
      data: echo_json(echo),
      media_herald: Phos.Orbject.S3.put_all!(media)
    }
  end

  defp echo_json(echo) do
    PhosWeb.Util.Viewer.echo_mapper(echo)
  end

  defp parse_time(time), do: DateTime.from_naive!(time, "Etc/UTC") |> DateTime.to_unix()
end
