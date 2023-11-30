defmodule Phos.PlatformNotification.Subscription do
  use GenServer

  @default_endpoint "https://iid.googleapis.com"
  @timeout 15_000

  @derive {Jason.Encoder, only: [:registration_tokens, :to]}
  defstruct [:registration_tokens, :to, :operation]

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  @spec init(Keyword.t()) :: {:ok, any()}
  def init(_opts) do
    {:ok, []}
  end

  def subscribe(token, topic, opts \\ [])
  def subscribe(token, topic, opts) do
    timeout = Keyword.get(opts, :timeout, @timeout)
    subs = %__MODULE__{registration_tokens: token, to: topic, operation: "batchAdd"}
    case Keyword.get(opts, :is_sync) do
      false -> GenServer.cast(__MODULE__, {:send_request, subs})
      _ -> GenServer.call(__MODULE__, {:send_request, subs}, timeout)
    end
  end

  def unsubscribe(token, topic, opts \\ [])
  def unsubscribe(token, topic, opts) do
    timeout = Keyword.get(opts, :timeout, @timeout)
    subs = %__MODULE__{registration_tokens: token, to: topic, operation: "batchRemove"}
    case Keyword.get(opts, :is_sync) do
      false -> GenServer.cast(__MODULE__, {:send_request, subs})
      _ -> GenServer.call(__MODULE__, {:send_request, subs}, timeout)
    end
  end

  def registered(token) do
    GenServer.call(__MODULE__, {:registered, token}, @timeout)
  end

  @impl true
  def handle_call({:send_request, subsciption}, _from, state) do
    case do_request(subsciption) do
      {:ok, %HTTPoison.Response{status_code: 200} = resp} ->
        res = Jason.decode!(resp.body) |> process_response()
        {:reply, {:ok, res}, state}
      {:error, err} ->
        {:reply, {:error, err.body}, state}
    end
  end

  @impl true
  def handle_call({:registered, token}, _from, state) do
    case do_get_list(token) do
      {:ok, %HTTPoison.Response{status_code: 200} = resp} ->
        res = Jason.decode!(resp.body)
        topics = get_in(res, [Access.key("rel", %{}), Access.key("topics", %{})]) |> Map.keys()
        scope  = Map.get(res, "scope")
        {:reply, {:ok, %{topics: topics, scope: scope}}, state}
      {:error, err} ->
        {:reply, {:error, err.body}, state}
    end
  end

  @impl true
  def handle_cast({:send_request, subs}, state) do
    spawn(fn -> do_request(subs) end)
    {:noreply, state}
  end

  defp bearer_token do
    with pool when not is_nil(pool) <- Sparrow.PoolsWarden.choose_pool(:fcm),
      project when not is_nil(project) <- Sparrow.FCM.V1.ProjectIdBearer.get_project_id(pool) do
      Sparrow.FCM.V1.TokenBearer.get_token(project)
    else
      nil ->
        raise ArgumentError, "authentication failed"
    end
  end

  defp do_request(subs) do
    body = normalize(subs)
    path = "/iid/v1:#{subs.operation}"
    HTTPoison.post(@default_endpoint <> path, body, headers())
  end

  defp do_get_list(token) do
    path = "/iid/info/#{token}?details=true"
    HTTPoison.get(@default_endpoint <> path, headers())
  end

  defp normalize(subs) do
    topic = case String.starts_with?(subs.to, "/topics/") do
      true -> subs.to
      _ -> "/topics/#{subs.to}"
    end
    token = case subs.registration_tokens do
      [_ | _] = tok -> tok
      _ -> [subs.registration_tokens]
    end

    Map.put(subs, :to, topic)
    |> Map.put(:registration_tokens, token)
    |> Jason.encode!
  end

  defp headers do
    [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{bearer_token()}"},
      {"access_token_auth", true}
    ]
  end

  defp process_response(%{"results" => res}) do
    final = %{success: 0, failed: 0, errors: []}
    Enum.reduce(res, final, fn v, %{success: suc, failed: failed, errors: errors} = acc ->
      case Map.values(v) do
        [] -> Map.put(acc, :success, suc + 1)
        _ ->
          err = Map.get(v, "error")
          Map.merge(acc, %{
            failed: failed + 1,
            errors: [ err | errors]
          })
      end
    end)
  end
  defp process_response(_), do: %{}

end
