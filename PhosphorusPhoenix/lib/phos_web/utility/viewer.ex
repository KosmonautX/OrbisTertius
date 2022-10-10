defmodule PhosWeb.Util.Viewer do

  @moduledoc """

  For our Viewer Helper function that moulds data Models into Views

  """
  alias Phos.Orbject.S3

  # Relationship Mapper
  def relationship_mapper(orb) do
    (if orb.initiator && Ecto.assoc_loaded?(orb.initiator) do
      %{initiator:
        %{data: %{username: orb.initiator.username,
                  user_id: orb.initiator.id
                 },
          links: %{self: PhosWeb.Router.Helpers.user_profile_path(PhosWeb.Endpoint, :show, orb.initiator.id)},
          media: (if orb.initiator.media, do: S3.get_all!("USR", orb.initiator.id, "profile"))
        }
      }
    end)
  end

  # User Mapper
  #
  #
  def user_mapper(user) do
    %{
      id: user.id,
      username: user.username,
      fyr_id: user.fyr_id,
      profile_pic: user.profile_pic,
      profile: user_profile_mapper(user),
    }
  end

  def user_profile_mapper(user) do
    %{private: user_private_mapper(user),
      public: user_public_mapper(user),
      personal: user_personal_orb_mapper(user)}
  end

  def user_private_mapper(user) do
    (if user.private_profile && Ecto.assoc_loaded?(user.private_profile) do
      %{data: %{geolocation: user.private_profile.geolocation}}
    end)
  end

  def user_personal_orb_mapper(user) do
    #extend to orb model in future
    (if user.personal_orb && Ecto.assoc_loaded?(user.personal_orb) do
      %{traits: user.personal_orb.traits}
    end)
  end

  def user_public_mapper(user) do
    (if user.public_profile && Ecto.assoc_loaded?(user.public_profile) do
      %{data:
        %{ birthday: user.public_profile.birthday,
           occupation: user.public_profile.occupation,
           bio: user.public_profile.bio,
           public_name: user.public_profile.public_name
        },
        links: %{self: PhosWeb.Router.Helpers.user_profile_path(PhosWeb.Endpoint, :show, user.id)},
        media: (if user.media, do: S3.get_all!("USR", user.id, "profile"))
      }
    end)
  end

  # Orb Mapper
  def orb_orb_mapper(orbs) do
    Enum.map(orbs, fn orb ->
      %{
        expiry_dt: DateTime.from_naive!(orb.extinguish, "Etc/UTC") |> DateTime.to_unix(),
        active: orb.active,
        available: orb.active,
        orb_uuid: orb.id,
        payload: %{source: orb.source,
                   init: %{username: orb.initiator.username, media: orb.initiator.media, media_asset: Phos.Orbject.S3.get!("USR", orb.initiator.fyr_id, "150x150")},
                   extinguishtime: DateTime.from_naive!(orb.extinguish, "Etc/UTC") |> DateTime.to_unix(),
                   user_id: orb.initiator.fyr_id,
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

  def post_orb_mapper(orbs) do
    Enum.map(orbs, fn orb ->
      %{
        orb_uuid: orb.id,
        force: true,
        user_id: orb.initiator.fyr_id,
        username: orb.initiator.username,
        user_media: true,
        expires_in: DateTime.diff(DateTime.from_naive!(orb.extinguish, "Etc/UTC"), DateTime.now!("Etc/UTC"), :second),
        title: orb.title,
        orb_nature: "01",
        media: orb.media,
        traits: orb.traits,
        info: orb.payload.info,
        where: orb.payload.where,
        tip: orb.payload.tip,
        when: orb.payload.when,
        geolocation:
          %{live:
            %{
              populate: !Enum.member?(orb.traits, "pin"),
              geohashes: Enum.reduce_while(orb.locations,[],fn o, acc ->
                unless length(acc) > 8, do: {:cont, [o.id |> :h3.to_string |> to_string() | acc]}, else: {:halt, acc} end),
              target: :h3.get_resolution(orb.central_geohash),
              geolock: true
          }}}
     end)
   end

  def fresh_orb_stream_mapper(orbs) do
    Enum.map(orbs, fn orb ->
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
     end)
  end

  # user.private_profile.geolocation -> socket.assigns.geolocation
  def profile_geolocation_mapper(geolocs) do
    Enum.map(geolocs, fn loc ->
      put_in(%{}, [String.to_atom(loc.id)],
        %{
          geohash: %{hash: loc.geohash, radius: 10}
        })
    end)
    |> Enum.reduce(fn x, y ->
        Map.merge(x, y, fn _k, v1, v2 -> v2 ++ v1 end)
      end)
  end


  # Index Live Orbs
  def live_orb_mapper(orbs) do
    Enum.filter(orbs, fn orb -> orb.active == true end)
  end


defp nested_put(nest) do
  if nest do
    nest
  else
    %{}
  end
 end
 end
