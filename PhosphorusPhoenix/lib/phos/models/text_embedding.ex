defmodule Phos.Models.TextEmbedding do
  use GenServer

  @impl true
  def init(_opts) do
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
    with %{embedding: embed} <- Nx.Serving.batched_run(Phos.Oracle.TextEmbedder, text),
          result <- Nx.to_list(embed) do
      {:reply, {:ok, result}, serving}
    else
      _ -> {:reply, {:ok, []}, serving}
    end
  end

  @impl true
  def handle_cast({:embedding, text, fun}, serving) when is_function(fun) do
    with %{embedding: embed} <- Nx.Serving.batched_run(Phos.Oracle.TextEmbedder, text),
          result <- Nx.to_list(embed) do
      apply(fun, [result])
    else
      err -> send(self(), {:error, err})
    end

    {:noreply, serving}
  end

  @impl true
  def handle_cast({:embedding, text, {mod, fun, opts}}, serving) do
    with %{embedding: embed} <- Nx.Serving.batched_run(Phos.Oracle.TextEmbedder, text),
          result <- Nx.to_list(embed) do
      apply(mod, fun, [result] ++ opts)
    else
      err -> send(self(), {:error, err})
    end

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
end
