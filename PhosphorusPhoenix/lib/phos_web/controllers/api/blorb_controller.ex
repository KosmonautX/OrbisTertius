defmodule PhosWeb.API.BlorbController do
  use PhosWeb, :controller
  use Phos.ParamsValidator, [
    :type, :active, :orb_id, :initiator_id,
    character: [:content, :count, :align, :resolution, :ext]
  ]

  alias Phos.Action
  alias Phos.Action.Blorb
  action_fallback PhosWeb.API.FallbackController

  def create(conn = %{assigns: %{current_user: user}}, params = %{"type" => type, "orb_id" => orb_id, "media" => [_|_] = media}) when type in ["img", "vid"] do
    with {:ok, attrs} <- blorb_constructor(user, params),
         {:ok, media} <- Phos.Orbject.Structure.apply_media_changeset(%{id: orb_id, archetype: "ORB", media: media}),
         {:ok, %Blorb{} = blorb} <- Action.create_blorb(attrs) do

      conn
      |> put_status(:created)
      |> render(:show, blorb: blorb, media: media)
    end
  end

  def create(conn = %{assigns: %{current_user: user}}, %{"orb_id" => _orb_id} = params) do
    with {:ok, attrs} <- blorb_constructor(user, params),
         {:ok, %Blorb{} = blorb} <- Action.create_blorb(attrs) do
      conn
      |> put_status(:created)
      |> render(:show, blorb: blorb)
    end
  end

  def update(conn = %{assigns: %{current_user: user}}, %{"id" => id} = params) do
    blorb = Action.get_blorb!(id)
    with true <- blorb.initiator.id == user.id,
         {:ok, attrs} <- blorb_constructor(user, params),
         {:ok, %Blorb{} = blorb} <- Action.update_blorb(blorb, attrs) do
      conn
      |> put_status(:ok)
      |> render(:show, blorb: blorb)
    else
      false -> {:error, :unauthorized}
    error -> error
    end
  end

  def delete(conn = %{assigns: %{current_user: user}}, %{"id" => id}) do
    blorb = Action.get_blorb!(id)
    with true <- blorb.initiator.id == user.id,
         {:ok, %Blorb{}} <- Action.delete_blorb(blorb) do
      send_resp(conn, :no_content, "")
    else
      false -> {:error, :unauthorized}
    error -> error
    end
  end

  def blorb_constructor(user, params) do
    constructor = sanitize(params)
    try do
      options =
        params
        |> Map.put("initiator_id", user.id)
      {:ok, Map.merge(constructor, options)}
    rescue
      ArgumentError -> {:error, :unprocessable_entity}
    end
  end

  def parse_params("id", data) when is_nil(data), do: Ecto.UUID.generate()
end
