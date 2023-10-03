defmodule PhosWeb.API.BlorbController do
  use PhosWeb, :controller
#   use Phos.ParamsValidator, [
#     :type, :active, :orb_id, :initiator_id,
#     character: [:content, :align, :resolution, :ext]
#   ]

# #   alias Phos.Action.Orb
#   action_fallback PhosWeb.API.FallbackController

#   def create(conn = %{assigns: %{current_user: user}}, params) do

#     with {:ok, attrs} <- blorb_constructor(user, params),
#          {:ok, %Orb{} = orb} <- Action.create_orb(attrs) do
#       conn
#       |> put_status(:created)
#       |> put_resp_header("location", ~p"/api/orbland/orbs/#{orb.id}")
#       |> render(:show, orb: orb)
#     end
#   end

#   def update(conn = %{assigns: %{current_user: user}}, %{"id" => id}) do
#     orb = Action.get_orb!(id)
#     with true <- orb.initiator.id == user.id,
#          {:ok, attrs} <- blorb_constructor(user, params),
#          {:ok, %Orb{} = orb} <- Action.update_orb(orb, attrs) do
#       conn
#       |> put_status(:ok)
#       |> put_resp_header("location", ~p"/api/orbland/orbs/#{orb.id}")
#       |> render(:show, orb: orb)
#     else
#       false -> {:error, :unauthorized}
#     error -> error
#     end
#   end

#   def blorb_constructor(user, params) do
#     constructor = sanitize(params)
#     try do
#       options =
#         params
#         |> Map.put("initiator_id", user.id)
#       {:ok, Map.merge(constructor, options)}
#     rescue
#       ArgumentError -> {:error, :unprocessable_entity}
#     end
#   end

#   def parse_params("id", data) when is_nil(data), do: Ecto.UUID.generate()
end
