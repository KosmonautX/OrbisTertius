defmodule Phos.Models.TokenClassification do
  use GenServer

  @impl true
  def init(_opts) do
    send(self(), :load_model)
    {:ok, []}
  end

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def classify(text) do
    try do
      GenServer.call(__MODULE__, {:classify, text})
    catch
      :exit, _ -> {:error, []}
    end
  end

  @impl true
  def handle_call({:classify, text}, _from, serving) do
    %{entities: result} = Nx.Serving.run(serving, text)
    {:reply, {:ok, result}, serving}
  end

  @impl true
  def handle_info(:load_model, _state) do
    {:ok, model} = Bumblebee.load_model(model_info(:model))
    {:ok, token} = Bumblebee.load_tokenizer(model_info(:token))

    serving = Bumblebee.Text.token_classification(model, token, aggregation: :same)
    :logger.info(%{
      message: "Model TokenClassification was loaded",
      state: :finished
    }, %{
        module: __MODULE__,
        action: :load_model,
        state: :loaded}
    )
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
