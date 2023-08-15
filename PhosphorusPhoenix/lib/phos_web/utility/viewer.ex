defmodule PhosWeb.Util.Viewer do

  @moduledoc """

  For our Viewer Helper function that moulds data Models into Views

  """

  import Phoenix.VerifiedRoutes, only: [path: 3]

  alias PhosWeb.Router
  alias Phos.Orbject.S3

  # Relationship Mapper
  def relationship_mapper(field, entity) do
    case field do
      {:self_relation, %Phos.Users.RelationRoot{} = self_relation} ->

        %{self:
          %{data: %{PhosWeb.Util.Viewer.user_relation_mapper(self_relation) | self_initiated: self_relation.initiator_id != entity.id},
            links: %{self: path(PhosWeb.Endpoint, Router, ~p"/api/folkland/others/#{entity.id}")}}}


      {:orbs, [%Phos.Action.Orb{} | _] = orbs} ->
        %{orbs:
          %{data: PhosWeb.Util.Viewer.orb_mapper(orbs),
          links: %{history: path(PhosWeb.Endpoint, Router, ~p"/api/userland/others/#{entity.id}/history")}}}

      {k, [%Phos.Comments.Comment{} | _] = comment} ->

        Map.new([{k, %{data: PhosWeb.Util.Viewer.comment_mapper(comment)}}])


      {k , %Phos.Users.User{} = user} ->
        Map.new([{k,
                  %{data: PhosWeb.Util.Viewer.user_mapper(user),
                    links: %{profile: path(PhosWeb.Endpoint, Router, ~p"/api/userland/others/#{user.id}")}}}])

      {k, %Phos.Action.Location{} = loc} ->

        Map.new([{k, %{data: PhosWeb.Util.Viewer.loc_mapper(loc)}}])

      {k, %Phos.Action.Orb{} = orb} ->

        Map.new([{k, %{data: PhosWeb.Util.Viewer.orb_mapper(orb)}}])

      {k, %Phos.Comments.Comment{} = comment} ->

        Map.new([{k, %{data: PhosWeb.Util.Viewer.comment_mapper(comment)}}])

      {k, %Phos.Message.Memory{} = memory} ->

        Map.new([{k, %{data: PhosWeb.Util.Viewer.memory_mapper(memory)}}])

      {k, %Phos.Users.RelationRoot{} = relation} ->

        Map.new([{k, %{data: %{PhosWeb.Util.Viewer.user_relation_mapper(relation) | self_initiated: relation.initiator_id != entity.id},
            links: %{self: path(PhosWeb.Endpoint, Router, ~p"/api/folkland/others/#{relation.initiator_id}")}}}])

      {:mutual , user} when is_map(user) ->
        Map.new([{:mutual,
                  %{data: PhosWeb.Util.Viewer.user_mapper(user),
                    links: %{profile: path(PhosWeb.Endpoint, Router, ~p"/api/userland/others/#{user.id}")}}}])

      _ -> %{}

    end
  end


  def relationship_reducer(entity) do
        entity
        |> Map.from_struct()
        |> Enum.reduce(%{}, fn({k,v}, acc) -> Map.merge(acc, relationship_mapper({k,v}, entity)) end)
  end


  def memory_mapper(memories = [%Phos.Message.Memory{} | _]), do: Enum.map(memories, &memory_mapper/1)
  def memory_mapper(memory) do
      %{just_a_memory_mapper(memory) | relationships: relationship_reducer(memory)}
  end

  def just_a_memory_mapper(memory) do
      %{
        id: memory.id,
        relationships: %{},
        user_source_id: memory.user_source_id,
        loc_subject_id: memory.loc_subject_id,
        rel_subject_id: memory.rel_subject_id,
        mem_subject_id: memory.mem_subject_id,
        orb_subject_id: memory.orb_subject_id,
        com_subject_id: memory.com_subject_id,
        cluster_subject_id: memory.cluster_subject_id,
        action_path: memory.action_path,
        message: memory.message,
        creationtime: memory.inserted_at |> DateTime.to_unix(:millisecond),
        mutationtime: memory.updated_at |> DateTime.to_unix(:millisecond),
        media: (if memory.media, do: S3.get_all!("MEM", memory.id, "public")),
        media_exists: memory.media
      }
  end

  def reverie_mapper(reverie) do
      %{
        id: reverie.id,
        relationships: relationship_reducer(reverie),
        read: reverie.read,
        creationtime: DateTime.from_naive!(reverie.inserted_at, "Etc/UTC") |> DateTime.to_unix(:millisecond),
        mutationtime: DateTime.from_naive!(reverie.updated_at, "Etc/UTC") |> DateTime.to_unix(:millisecond),
      }
  end

  # User Mapper
  def user_mapper(user) do
    %{
      id: user.id,
      username: user.username,
      confirmed_at: user.confirmed_at,
      fyr_id: user.fyr_id,
      profile: user_profile_mapper(user),
      ally_count: user.ally_count,
      mutual_count: user.mutual_count,
      relationships: relationship_reducer(user),
      creationtime: DateTime.from_naive!(user.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
      mutationtime: DateTime.from_naive!(user.updated_at, "Etc/UTC") |> DateTime.to_unix(),
      media: (if user.media, do: S3.get_all!("USR", user.id, "public"))
    }
  end

  def user_presence_mapper(users) when is_list(users), do: Enum.map(users, &user_presence_mapper/1)
  def user_presence_mapper(user) do
    %{
      data: Map.take(user, [:id, :username, :town, :online_at])
      |> Map.put(:media, (if user.media, do:  %{"public/profile/lossy" => Phos.Orbject.S3.get!("USR", user.id, "public/profile/lossy")})),
      meta: Map.take(user, [:phx_ref, :phx_ref_prev, :topic]) |> topic_mapper()
    }
  end

  def topic_mapper(%{topic: "memory:terra:" <> hash} = meta), do: %{meta | topic: hash}
  def topic_mapper(meta), do: meta

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
    (if profile && !is_nil(profile) && Ecto.assoc_loaded?(profile) do
      %{data: %{
           fcm_token: profile.fcm_token,
           beacon: (if profile.beacon do
             for {k , v}  <- Map.from_struct(profile.beacon), into: %{} do
                     case k do
                       :scope ->
                         {:scope, v}
                       _ ->
                     {k,
                      (unless is_nil(v) do
                       %{scope: v.scope,
                           subscribe: v.subscribe,
                           unsubscribe: v.unsubscribe
                          }
                       else
                         %{}
                       end)}
                    end
                  end
           end)}}
      end)
  end

  def user_public_mapper(user) do
    (if user.public_profile  && Ecto.assoc_loaded?(user.public_profile) do
      %{data:
        %{ birthday: (if user.public_profile.birthday, do: user.public_profile.birthday |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()),
           occupation: user.public_profile.occupation,
           bio: user.public_profile.bio,
           public_name: user.public_profile.public_name,
           profile_pic: user.public_profile.profile_pic,
           banner_pic: user.public_profile.banner_pic,
           traits: (user.public_profile.traits || []) -- ["exile"],
           territories: user.public_profile.territories,
           # assemblies: Enum.reduce(user.public_profile.territories, [], fn terr, acc -> [loc_mapper(terr) | acc] end) |> Enum.uniq_by(&(&1.midhash)),
           places: user.public_profile.places
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
  def orb_mapper(orbs = [%Phos.Action.Orb{} | _]), do: Enum.map(orbs, &orb_mapper/1)
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
      parent: parent_orb_mapper(orb.parent),
      media: (if orb.media, do: S3.get_all!("ORB", orb.id, "public")),
      comment_count: orb.comment_count
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
                url: orb.payload.ext_link.url,
                referral: orb.payload.ext_link.referral
              })
        }
      }
    end)
  end

  defp parent_orb_mapper(%Phos.Action.Orb{} = orb), do: orb_mapper(orb)
  defp parent_orb_mapper(_), do: %{}

  ## Comment Mapper
  def comment_mapper(comments = [%Phos.Comments.Comment{} | _]), do: Enum.map(comments, &comment_mapper/1)
  def comment_mapper(comment= %Phos.Comments.Comment{}) do
    %{
      id: comment.id,
      active: comment.active,
      child_count: comment.child_count,
      body: comment.body,
      path: to_string(comment.path),
      initiator_id: comment.initiator_id,
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
        time: DateTime.from_naive!(echo.inserted_at,"Etc/UTC") |> DateTime.to_unix(),
        creationtime: DateTime.from_naive!(echo.inserted_at, "Etc/UTC") |> DateTime.to_unix(),
        mutationtime: DateTime.from_naive!(echo.updated_at, "Etc/UTC") |> DateTime.to_unix()
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

  def loc_mapper(loc) when is_integer(loc) do
    %{
      hash: loc,
      midhash: loc |> Phos.Mainland.Sphere.middle(),
      town: loc |> Phos.Mainland.Sphere.locate()
    }
  end

  def loc_mapper(locs = [%Phos.Action.Location{} | _]), do: Enum.map(locs, &loc_mapper/1)
  def loc_mapper(%Phos.Action.Location{} = loc) do
    %{
      hash: loc.id,
      midhash: loc.id |> Phos.Mainland.Sphere.middle(),
      town: loc.id |> Phos.Mainland.Sphere.locate(),
      last_memory_id: loc.last_memory_id,
      relationships: relationship_reducer(loc),
    }
  end


  # defp nested_put(nest) do
  #   if nest do
  #     nest
  #   else
  #     %{}
  #   end
  # end
 end
