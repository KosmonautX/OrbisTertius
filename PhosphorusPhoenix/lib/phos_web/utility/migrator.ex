defmodule PhosWeb.Util.Migrator do
  @moduledoc """

  For our Migration Utility functions that transform data from our Heimdallr APIs to our internal data models

  """

  def user_profile(id) do
    unless map_size(user = Phos.External.HeimdallrClient.get_dyn_user(id)) == 0  do
      user_internal = %{"username" => user["payload"]["username"],
                      "fyr_id" => user["user_id"],
                      "media" => user["payload"]["media"],
                      "public_profile" =>
                        %{"birthday" => user["payload"]["birthday"],
                          "bio" => user["payload"]["bio"]},
                      "profile_pic" => user["payload"]["profile_pic"]}
      if(user["geolocation"]) do
        geo_map = for loc <- Map.keys(user["geolocation"]) do
          user["geolocation"][loc]
          |> Map.put("id", loc)
          |> Map.put("geohash", :h3.from_string(to_charlist(Map.get(user["geolocation"][loc]["geohashing"], "hash"))))
        end
        Map.put(user_internal, "private_profile", %{"geolocation" => geo_map}) |>
          Phos.Users.create_user()
      else
        Phos.Users.create_user(user_internal)
      end
    end
  end
end
