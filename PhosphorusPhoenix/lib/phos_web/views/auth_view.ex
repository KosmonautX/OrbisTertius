defmodule PhosWeb.AuthView do
  use PhosWeb, :view

  def render("callback.json", %{user: %Phos.Users.User{id: id, username: username} = user}) do
    #teritories = parse_teritories(user)
    #opts = %{user_id: id, role: "pleb", username: username, teritory: teritories}
    case PhosWeb.Menshen.Auth.generate_user(id) do
      {:ok, token, _claims} ->
        %{
          id: id,
          token: token,
        }
      {:error, reason} -> render_one(reason, __MODULE__, "error.json")
    end

  end

  def render("unauthorized.json", _) do
    %{
      message: "Unauthorized",
      status: 401
    }
  end

  def render("error.json", %{reason: reason}) do
    %{
      message: reason,
      status: 400
    }
  end

  def render("error.json", %{auth: reason}) do
    %{
      message: reason,
      status: 400
    }
  end

  defp parse_teritories(%{private_profile: %Phos.Users.Private_Profile{geolocation: geolocations}}) do
    Enum.reduce(geolocations, %{}, fn %{chronolock: chronolock, geohash: hash, location_description: desc}, acc ->
      Map.put(acc, String.downcase(desc), %{radius: chronolock, hash: :h3.to_string(hash)})
    end)
  end
  defp parse_teritories(_), do: %{}
end
