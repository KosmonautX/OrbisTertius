defmodule Phos.Oracle do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def load_textembedder_serving do
    {:ok, model} = Bumblebee.load_model(model_info(:textembedder, :model))
    {:ok, token} = Bumblebee.load_tokenizer(model_info(:textembedder, :model))

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


  defp model_info(role, type) do
    #Keyword.put_new(:dir, :code.priv_dir(:phos) |> to_string() |> Kernel.<>("/models"))
    case Application.get_env(:phos, __MODULE__) |> Enum.into(%{}) do
      %{^role => %{source: :local, dir: dir}} = conf -> {:local, "#{dir}/#{Keyword.get(conf, type)}"}
      %{^role => conf} -> {:hf, Keyword.get(conf, type)}
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
