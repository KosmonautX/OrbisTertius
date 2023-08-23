defmodule Phos.Models.TextEmbedding do
  use GenServer

  @impl true
  def init(_opts) do
    send(self(), :load_model)
    {:ok, []}
  end

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def run(text) do
    try do
      GenServer.call(__MODULE__, {:embedding, text})
    catch
      :exit, _ -> {:error, []}
    end
  end

  def run_async(text, callback), do: GenServer.cast(__MODULE__, {:embedding, text, callback})

  @impl true
  def handle_call({:embedding, text}, _from, serving) do
    with %{embedding: embed} <- Nx.Serving.run(serving, text),
          result <- Nx.to_list(embed) do
      {:reply, {:ok, result}, serving}
    else
      _ -> {:reply, {:ok, []}, serving}
    end
  end

  @impl true
  def handle_cast({:embedding, text, fun}, serving) when is_function(fun) do
    with %{embedding: embed} <- Nx.Serving.run(serving, text),
          result <- Nx.to_list(embed) do
      apply(fun, [result])
    else
      err -> send(self(), {:error, err})
    end

    {:noreply, serving}
  end

  @impl true
  def handle_cast({:embedding, text, {mod, fun, opts}}, serving) do
    with %{embedding: embed} <- Nx.Serving.run(serving, text),
          result <- Nx.to_list(embed) do
      apply(mod, fun, [result] ++ opts)
    else
      err -> send(self(), {:error, err})
    end

    {:noreply, serving}
  end

  @impl true
  def handle_info(:load_model, _state) do
    {:ok, model} = Bumblebee.load_model(model_info(:model))
    {:ok, token} = Bumblebee.load_tokenizer(model_info(:token))

    serving = Bumblebee.Text.TextEmbedding.text_embedding(model, token)

    :logger.info(%{
      message: "Model TextEmbedding was loaded",
      state: :finished
    }, %{
        module: __MODULE__,
        action: :load_model,
        state: :loaded}
    )
    {:noreply, serving}
  end

  @impl true
  def handle_info({:error, err}, serving) do
    :logger.error(%{
      message: inspect(err),
      state: :error,
    }, %{
      module: __MODULE__,
      action: :error_logger,
      state: :info
    })

    {:noreply, serving}
  end

  defp config do
    conf = Application.get_env(:phos, __MODULE__)

    conf
    |> Keyword.put_new(:dir, :code.priv_dir(:phos) |> to_string() |> Kernel.<>("/models"))
    |> Keyword.put_new(:token, Keyword.get(conf, :model))
    |> Keyword.put_new(:source, :hf)
    |> Enum.into(%{})
  end

  defp model_info(type) do
    case config() do
      %{source: :local, dir: dir} = conf -> {:local, "#{dir}/#{Map.get(conf, type)}"}
      conf -> {:hf, Map.get(conf, type)}
    end
  end
end
