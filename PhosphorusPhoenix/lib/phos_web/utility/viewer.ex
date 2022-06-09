defmodule PhosWeb.Util.Viewer do

  @moduledoc """

  For our Viewer Helper function that moulds data Models into Views

  """
  # Orb Mapper
  def orb_orb_mapper(orbs) do
    Enum.map(orbs, fn orb ->
      %{
        expiry_dt: DateTime.from_naive!(orb.extinguish, "Etc/UTC") |> DateTime.to_unix(),
        active: orb.active,
        available: orb.active,
        orb_uuid: orb.id,
        payload: %{orb_nature: orb.orb_nature,
          init: %{username: orb.users.username, media: orb.users.media, media_asset: Phos.Orbject.S3.get!("USR", orb.users.fyr_id, "150x150")},
          extinguishtime: DateTime.from_naive!(orb.extinguish, "Etc/UTC") |> DateTime.to_unix(),
          user_id: orb.users.fyr_id,
          where: orb.payload.where,
          creationtime: DateTime.from_naive!(orb.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
          media: orb.media,
          title: orb.title,
          info: orb.payload.info,
          media_asset: Phos.Orbject.S3.get!("ORB", orb.id, "1920x1080")},
        geolocation: %{
          hashes: [],
          radius: 0,
          geolock: false,
          hash: orb.central_geohash,
          live: %{geohashes: []},
          populate: true,
          geolock: true,
          target: 8#:h3.get_resolution(orb.central_geohash)
        }
      }
    end)
  end

  def fresh_orb_stream_mapper(orbs) do
    Enum.map(orbs, fn orb ->
      %{
        expiry_dt: DateTime.from_naive!(orb.extinguish, "Etc/UTC") |> DateTime.to_unix(),
        active: orb.active,
        available: orb.active,
        orb_uuid: orb.id,
        payload: %{orb_nature: orb.orb_nature,
          init: %{username: orb.users.username, media: orb.users.media, media_asset: Phos.Orbject.S3.get!("USR", orb.users.fyr_id, "150x150")},
          extinguishtime: DateTime.from_naive!(orb.extinguish, "Etc/UTC") |> DateTime.to_unix(),
          user_id: orb.users.fyr_id,
          where: orb.payload.where,
          creationtime: DateTime.from_naive!(orb.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
          media: orb.media,
          title: orb.title,
          info: orb.payload.info,
          media_asset: Phos.Orbject.S3.get!("ORB", orb.id, "1920x1080")},
        geolocation: %{
          hashes: [],
          radius: 0,
          hash: orb.central_geohash
        }
      }
    end)
  end

  # Update Orbs Mapper
  def update_orb_mapper(orb) do
      %{
        "title" => orb["title"],
        "media" => orb["media"],
        "payload" => orb["payload"],
        "traits" => orb["traits"]
      }
  end

  # Index Live Orbs
  def live_orb_mapper(orbs) do
    Enum.filter(orbs, fn orb -> orb.active == true end)
  end
end
