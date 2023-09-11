defmodule Phos.Oracle do
  use Supervisor
  @moduledoc """
  Orchestrator for Models running on Phos
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def load_textembedder_serving do
    {:ok, model} = Bumblebee.load_model(model_info(:textembedder))
    {:ok, token} = Bumblebee.load_tokenizer(model_info(:textembedder))

    serving = Bumblebee.Text.TextEmbedding.text_embedding(model, token, embedding_processor: :l2_norm, defn_options: [compiler: EXLA])

    :logger.info(%{
      message: "TextEmbedder was initiated",
      state: :finished
    }, %{
        module: __MODULE__,
        action: :load_model,
        state: :loaded}
    )
    serving
  end


  defp model_info(role) do
    case Application.get_env(:phos, __MODULE__) |> Enum.into(%{}) do
      %{^role => %{source: :local, dir: dir, model: model}} -> {:local, "#{dir}/#{model}"}
      %{^role => %{source: :hf, model: model}} -> {:hf, model}
      _ -> "role mismatch"
    end
  end


  @impl true
  def init(_opts) do
    children  = [
      {Nx.Serving,
       name: Phos.Oracle.TextEmbedder,
       serving: load_textembedder_serving(),
       batch_timeout: 10},
      Phos.Models.TextEmbedding
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
 end
