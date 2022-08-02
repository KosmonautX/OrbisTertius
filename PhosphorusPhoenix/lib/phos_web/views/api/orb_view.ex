defmodule PhosWeb.API.OrbView do
  use PhosWeb, :view
  alias PhosWeb.API.OrbView

  def render("index.json", %{orbs: orbs}) do
    %{data: render_many(orbs, OrbView, "orb.json")}
  end

  def render("show.json", %{orb: orb}) do
    %{data: render_one(orb, OrbView, "orb.json")}
  end

  def render("orb.json", %{orb: orb}) do
    %{
      expiry_time: DateTime.from_naive!(orb.extinguish, "Etc/UTC") |> DateTime.to_unix(),
      active: orb.active,
      available: orb.active,
      orb_uuid: orb.id,
      title: orb.title,
      initiator: (if orb.initiator do %{username: orb.initiator.username,
                  media: orb.initiator.media,
                  media_asset: (if orb.initiator.media && orb.initiator.fyr_id, do: Phos.Orbject.S3.get!("USR", orb.initiator.fyr_id, "150x150")),
                  user_id: orb.initiator.fyr_id || orb.initiator.id
                  }
          end),
      creationtime: DateTime.from_naive!(orb.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
      source: orb.source,
      traits: orb.traits,
      payload: (if orb.payload do %{
        where: orb.payload.where,
        inner_title: orb.payload.inner_title,
        info: orb.payload.info,
        media: orb.media,
        media_asset: (if orb.media, do: Phos.Orbject.S3.get!("ORB", orb.id, "1920x1080"))
        }
        end),
      geolocation: %{
        hash: orb.central_geohash
      }
    }
  end
end
