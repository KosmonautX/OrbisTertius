defmodule PhosWeb.Util.Viewer do

  @moduledoc """

  For our Viewer Helper function that moulds data Models into Views

  """
  alias Phos.Orbject.S3

  # Relationship Mapper
  def relationship_mapper(field, entity) do
    case field do
      {:self_relation, %Phos.Users.RelationRoot{} = self_relation} ->

        %{self:
          %{data: %{PhosWeb.Util.Viewer.user_relation_mapper(self_relation) | self_initiated: self_relation.initiator_id != entity.id},
            links: %{self: PhosWeb.Router.Helpers.friend_path(PhosWeb.Endpoint, :show_others, entity.id)}}}


      {:orbs, [%Phos.Action.Orb{} | _] = orbs} ->
        %{orbs:
          %{data: PhosWeb.Util.Viewer.orb_mapper(orbs),
          links: %{history: PhosWeb.Router.Helpers.orb_path(PhosWeb.Endpoint, :show_history, entity.id)}}}


      {:friend, %Phos.Users.User{} = friend} ->

        %{friend:
          %{data: PhosWeb.Util.Viewer.user_mapper(friend),
            links: %{profile: PhosWeb.Router.Helpers.user_profile_path(PhosWeb.Endpoint, :show, friend.id)}}}

      {:initiator, %Phos.Users.User{} = initiator} ->

        %{initiator:
          %{data: PhosWeb.Util.Viewer.user_mapper(initiator),
            links: %{profile: PhosWeb.Router.Helpers.user_profile_path(PhosWeb.Endpoint, :show, initiator.id)}}}

      {:acceptor, %Phos.Users.User{} = acceptor} ->

        %{acceptor:
          %{data: PhosWeb.Util.Viewer.user_mapper(acceptor),
            links: %{profile: PhosWeb.Router.Helpers.user_profile_path(PhosWeb.Endpoint, :show, acceptor.id)}}}


      _ -> %{}

    end
  end

  def relationship_reducer(entity) do
    entity
    |> Map.from_struct()
    |> Enum.reduce(%{}, fn({k,v}, acc) -> Map.merge(acc, relationship_mapper({k,v}, entity)) end)
  end

  # User Mapper
  def user_mapper(user) do
    %{
      id: user.id,
      username: user.username,
      fyr_id: user.fyr_id,
      profile: user_profile_mapper(user),
      relationships: relationship_reducer(user),
      creationtime: DateTime.from_naive!(user.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
      mutationtime: DateTime.from_naive!(user.updated_at, "Etc/UTC") |> DateTime.to_unix(),
      media: (if user.media, do: S3.get_all!("USR", user.id, "public"))
    }
  end

  def user_profile_mapper(user) do
    %{private: user_private_mapper(user),
      public: user_public_mapper(user),
    }
  end

  def user_private_mapper(%{private_profile: profile}) do
    (if profile && Ecto.assoc_loaded?(profile) do
      %{data: %{geolocation: profile.geolocation}}
    end)
  end

  def user_private_mapper(profile) do
    (if profile && Ecto.assoc_loaded?(profile) do
      %{data: %{
           geolocation: profile.geolocation,
        }}
    end)
  end

  def user_integration_mapper(%{integrations: profile}) do
    (if Ecto.assoc_loaded?(profile) do
      %{data: %{
           fcm_token: profile.fcm_token,
        }}
    end)
  end

  def user_public_mapper(user) do
    (if user.public_profile && Ecto.assoc_loaded?(user.public_profile) do
      %{data:
        %{ birthday: (if user.public_profile.birthday, do: user.public_profile.birthday |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()),
           occupation: user.public_profile.occupation,
           bio: user.public_profile.bio,
           public_name: user.public_profile.public_name,
           profile_pic: user.public_profile.profile_pic,
           banner_pic: user.public_profile.banner_pic,
           traits: user.public_profile.traits,
           territories: user.public_profile.territories
        }
      }
    end)
  end

  # User RelationRoot Mapper
  def user_relation_mapper(rel) do
    %{
      relation_id: rel.id,
      state: rel.state,
      initiator_id: rel.initiator_id,
      acceptor_id: rel.acceptor_id,
      creationtime: DateTime.from_naive!(rel.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
      mutationtime: DateTime.from_naive!(rel.updated_at, "Etc/UTC") |> DateTime.to_unix(),
      self_initiated: rel.self_initiated,
      relationships: relationship_reducer(rel),
      media: (if rel.self_initiated , do: S3.get_all!("USR", rel.acceptor_id, "public"), else: S3.get_all!("USR", rel.initiator_id, "public"))
    }
  end

  # Orb Mapper
  #
  def orb_mapper(orbs = [%Phos.Action.Orb{} | _]) do
    Enum.map(orbs, fn orb ->
      orb_mapper(orb)
    end)
  end

  def orb_mapper(orb = %Phos.Action.Orb{}) do
    %{
      expiry_time: (if orb.extinguish, do: DateTime.from_naive!(orb.extinguish, "Etc/UTC") |> DateTime.to_unix()),
      active: orb.active,
      orb_uuid: orb.id,
      title: orb.title,
      relationships: relationship_reducer(orb),
      creationtime: DateTime.from_naive!(orb.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
      mutationtime: DateTime.from_naive!(orb.updated_at, "Etc/UTC") |> DateTime.to_unix(),
      source: orb.source,
      traits: orb.traits,
      payload: orb_payload_mapper(orb),
      geolocation: %{
        hash: orb.central_geohash
      },
      media: (if orb.media, do: S3.get_all!("ORB", orb.id, "public"))
    }
  end

  def orb_payload_mapper(orb) do
    (if orb.payload do
      %{data:
        %{ where: orb.payload.where,
           inner_title: orb.payload.inner_title,
           info: orb.payload.info,
           tip: orb.payload.tip,
           when: orb.payload.when,
           ext_link: (if !is_nil(orb.payload.ext_link),
          do: %{
                name: orb.payload.ext_link.name,
                url: orb.payload.ext_link.url
              })
        }
      }
    end)
  end

  ## Comment Mapper
  def comment_mapper(comment= %Phos.Comments.Comment{}) do
    %{
      id: comment.id,
      active: comment.active,
      child_count: comment.child_count,
      body: comment.body,
      path: to_string(comment.path),
      parent_id: comment.parent_id,
      orb_id: comment.orb_id,
      relationships:  PhosWeb.Util.Viewer.relationship_reducer(comment),
      creationtime: DateTime.from_naive!(comment.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
      mutationtime: DateTime.from_naive!(comment.updated_at, "Etc/UTC") |> DateTime.to_unix()
    }

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

  def echo_mapper(echo) do
      %{
        source: echo.source,
        destination: echo.destination,
        source_archetype: echo.source_archetype,
        destination_archetype: echo.destination_archetype,
        subject_archetype: echo.subject_archetype,
        subject: echo.subject,
        message: echo.message,
        time: DateTime.from_naive!(echo.inserted_at,"Etc/UTC") |> DateTime.to_unix()
      }
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
      Map.merge(x, y, fn _k, v1, v2 -> v2 ++ v1  end)
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
