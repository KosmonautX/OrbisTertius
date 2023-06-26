defmodule Phos.Action do
  @moduledoc """
  The Action context.
  """

  import Ecto.Query, warn: false

  alias Phos.Repo
  alias Phos.Action.{Orb, Orb_Location}

  @doc """
  Returns the list of orbs.

  ## Examples

  iex> list_orbs()
  [%Orb{}, ...]

  """
  def list_orbs(filters \\ []) do
    default_query = from o in Orb, preload: [:initiator], order_by: [desc: o.inserted_at], limit: 12
    query = case Kernel.length(filters) do
              0 -> default_query
              _ -> advanced_orb_listing(filters, default_query)
            end

    Repo.all(query)
  end

  # orb filtering lens
  defp advanced_orb_listing(filters, default_query) do
    case Keyword.get(filters, :initiator_id) do
      ids when is_list(ids) ->
        ff =  Keyword.reject(filters, fn {key, _val} -> key == :initiator_id end)
        from q in default_query, where: q.initiator_id in ^ids, where: ^ff
      _ -> from q in default_query, where: ^filters
    end
  end

  #   @doc """
  #   Gets a single orb.

  #   Raises `Ecto.NoResultsError` if the Orb does not exist.

  #   ## Examples

  #       iex> get_orb!(123)
  #       %Orb{}

  #       iex> get_orb!(456)
  #       ** (Ecto.NoResultsError)

  #   """
  #

  def get_orb(id) when is_binary(id) do
    # parent_path = "*.#{Phos.Utility.Encoder.encode_lpath(id)}.*"
    query =
      from o in Orb,
        preload: [:locations, :initiator, :parent],
        where: o.id == ^id,
        inner_lateral_join: p in subquery(
          from p in Orb,
            where: p.parent_id == ^id,
            select: %{count: count(p)}
        ),
        inner_lateral_join: c in subquery(
          from c in Phos.Comments.Comment,
          where: c.orb_id == ^id,
          select: %{count: count()}
        ),
        select_merge: %{number_of_repost: p.count, comment_count: c.count},
        limit: 1
    case Repo.one(query) do
      %Orb{} = orb -> {:ok, orb}
      _ -> {:error, :not_found}
    end
  end

  def get_orb(orb_id, your_id) do
    from(orbs in Orb,
      where: orbs.id == ^orb_id,
      inner_join: initiator in assoc(orbs, :initiator),
      left_join: branch in assoc(initiator, :relations),
      on: branch.friend_id == ^your_id,
      left_join: root in assoc(branch, :root),
      select_merge: %{initiator: %{initiator | self_relation: root}},
      inner_lateral_join: c in subquery(
        from c in Phos.Comments.Comment,
        where: c.orb_id == ^orb_id,
        select: %{count: count()}
      ),
      select_merge: %{comment_count: c.count})
      |> Repo.one()
  end

  def get_orb!(id), do: Repo.get!(Orb, id) |> Repo.preload([:locations, :initiator])
  def get_orb_by_fyr(id), do: Repo.get_by(Phos.Users.User, fyr_id: id)

  def list_all_active_orbs(options \\ []) do
    page = Keyword.get(options, :page, 1)
    offset = Keyword.get(options, :offset, 20)
    query = from o in Orb, where: o.active == true, preload: [:initiator], order_by: [desc: :inserted_at], limit: ^offset, offset: ^((page - 1) * offset)
    Repo.all(query)
  end

  def active_orbs_by_geohashes(hashes) do
    from(l in Orb_Location,
      where: l.location_id in ^hashes,
      left_join: orbs in assoc(l, :orbs),
      where: orbs.active == true,
      preload: [orbs: :initiator],
      order_by: [desc: orbs.inserted_at])
      |> Repo.all(limit: 32)
      |> Enum.map(fn orb -> orb.orbs end)
  end

  def orbs_by_geohashes({hashes, your_id}) do
    from(o in Phos.Action.Orb,
      as: :orb,
      where: o.userbound != true,
      inner_join: l in Phos.Action.Orb_Location, on: l.location_id in ^hashes and l.orb_id == o.id,
      inner_join: initiator in assoc(o, :initiator),
      left_join: branch in assoc(initiator, :relations),
      on: branch.friend_id == ^your_id,
      left_join: root in assoc(branch, :root),
      select_merge: %{initiator: %{initiator | self_relation: root}},
      inner_lateral_join:
      c_count in subquery(
        from(c in Phos.Comments.Comment,
          where: c.orb_id == parent_as(:orb).id,
          select: %{count: count()}
        )
      ),
      select_merge: %{comment_count: c_count.count})
  end

  def orbs_by_geohashes({hashes, your_id}, opts) do
    limit = Keyword.get(opts, :limit, 24)
    orbs_by_geohashes({hashes, your_id})
    |> Repo.Paginated.all([{:limit, limit} | opts])
    |> (&(Map.put(&1, :data, &1.data |> Phos.Repo.Preloader.lateral(:comments, limit: 3, order_by: {:asc, :inserted_at}, assocs: [:initiator, parent: [:initiator]])))).()
  end


  def orbs_by_geotraits({hashes, your_id}, traits, opts) do
    sort = Keyword.get(opts, :sort_attribute, :inserted_at)
    limit = Keyword.get(opts, :limit, 12)

    orbs_by_geohashes({hashes, your_id})
    |> where([o], fragment("? @> ?", o.traits, ^traits))
    |> Repo.Paginated.all([{:sort_attribute, sort}| [{:limit, limit} | opts]])
  end

  def users_by_geohashes({hashes, your_id}, page, sort_attribute \\ :inserted_at, limit \\ 12) do
    from(l in Orb_Location,
      as: :l,
      where: l.location_id in ^hashes,
      inner_join: orbs in assoc(l, :orbs),
      where: orbs.userbound == true and fragment("? != '[]'", orbs.traits),
      inner_join: initiator in assoc(orbs, :initiator),
      as: :user,
      select: initiator,
      distinct: initiator.id,
      left_join: branch in assoc(initiator, :relations),
      on: branch.friend_id == ^your_id,
      left_join: root in assoc(branch, :root),
      select_merge: %{self_relation: root},
      inner_lateral_join:
      a_count in subquery(
        from(r in Phos.Users.RelationBranch,
          where: r.user_id == parent_as(:user).id and not is_nil(r.completed_at),
          select: %{count: count()}
        )
      ),
      left_lateral_join:
      mutual in subquery(
        from(r in Phos.Users.RelationBranch,
          where: r.user_id == parent_as(:user).id and not is_nil(r.completed_at),
          inner_join: friend in assoc(r, :friend),
          inner_join: mutual in assoc(friend, :relations),
          on: mutual.friend_id == ^your_id and not is_nil(r.completed_at),
          select: %{friend | count: over(count(), :ally_partition)},
          windows: [ally_partition: [partition_by: :user_id]]
        )
      ),
      select_merge: %{mutual_count: mutual.count, ally_count: a_count.count, mutual: mutual})
      |> Repo.Paginated.all([page: page, sort_attribute: sort_attribute, limit: limit])
      |> (&(Map.put(&1, :data, &1.data |> Repo.Preloader.lateral(:orbs, [limit: 5])))).()
      #|> (&(Map.put(&1, :data, &1.data |> Repo.Preloader.lateral(:allies, [limit: 3, order_by: {:desc, :completed_at}, assocs: [:friend]])))).()
  end

  def notifiers_by_geohashes(hashes) do
    from(l in Orb_Location,
      as: :l,
      where: l.location_id in ^hashes,
      left_join: orbs in assoc(l, :orbs),
      on: orbs.userbound == true,
      inner_join: initiator in assoc(orbs, :initiator),
      on: initiator.integrations["beacon"]["location"]["scope"] == true,
      distinct: initiator.integrations["fcm_token"],
      select: initiator.integrations)
      |> Repo.all()
  end

  def orb_initiator_by_geohashes(hashes) do
    from(l in Orb_Location,
      as: :l,
      where: l.location_id in ^hashes,
      left_join: orbs in assoc(l, :orbs),
      on: orbs.userbound == true,
      inner_join: initiator in assoc(orbs, :initiator),
      on: initiator.integrations["beacon"]["location"]["scope"] == true,
      distinct: initiator.id,
      select: initiator.id)
    |> Repo.all()
  end

  def orbs_by_friends(your_id, page, sort_attribute \\ :inserted_at, limit \\ 12) do
    from(orbs in Orb,
      as: :o,
      where: not fragment("? @> ?", orbs.traits, ^["mirage"]),
      inner_join: initiator in assoc(orbs, :initiator),
      inner_join: branch in assoc(initiator, :relations),
      on: branch.friend_id == ^your_id and not is_nil(branch.completed_at),
      inner_join: root in assoc(branch, :root),
      select_merge: %{initiator: %{initiator | self_relation: root}},
      inner_lateral_join: c in subquery(
        from c in Phos.Comments.Comment,
        where: c.orb_id == parent_as(:o).id,
        select: %{count: count()}
      ),
      select_merge: %{comment_count: c.count})
      |> Repo.Paginated.all(page, sort_attribute, limit)
  end


  def orbs_by_initiators(user_ids, page, opts \\ %{})
  def orbs_by_initiators(user_ids, page, %{"traits" => traits} = opts) do
    sort_attribute = Map.get(opts, :sort_attribute, :inserted_at)
    limit = Map.get(opts, :limit, 12)
    from(o in Orb,
      as: :o,
      where: o.initiator_id in ^user_ids and not fragment("? @> ?", o.traits, ^["mirage"]) and fragment("? @> ?", o.traits, ^traits),
      preload: [:initiator],
      inner_lateral_join: c in subquery(
        from c in Phos.Comments.Comment,
        where: c.orb_id == parent_as(:o).id,
        select: %{count: count()}
      ),
      select_merge: %{comment_count: c.count})
      |> Repo.Paginated.all(page, sort_attribute, limit)
  end

  def orbs_by_initiators(user_ids, page, opts) do
    sort_attribute = Map.get(opts, :sort_attribute, :inserted_at)
    limit = Map.get(opts, :limit, 12)
    from(o in Orb,
      as: :o,
      where: o.initiator_id in ^user_ids and not fragment("? @> ?", o.traits, ^["mirage"]),
      preload: [:initiator],
      inner_lateral_join: c in subquery(
        from c in Phos.Comments.Comment,
        where: c.orb_id == parent_as(:o).id,
        select: %{count: count()}
      ),
      select_merge: %{comment_count: c.count})
      |> Repo.Paginated.all(page, sort_attribute, limit)
  end


  def get_active_orbs_by_geohashes(ids) do
    query =
      from l in Orb_Location,
      as: :l,
      where: l.location_id in ^ids,
      preload: [:orbs, :locations],
      inner_lateral_join: c in subquery(
        from c in Phos.Comments.Comment,
        where: c.orb_id == parent_as(:l).orb_id,
        select: %{count: count()}
      ),
      select_merge: %{comment_count: c.count}

    Repo.all(query, limit: 32)
    |> Enum.map(fn orbloc -> Map.put(orbloc.orbs, :comment_count, orbloc.comment_count) end)
    # |> Enum.map(fn orb -> orb.orbs end)
    |> Enum.filter(fn orb -> orb.active == true  end)
  end

  def get_active_orbs_by_initiator(user_id) do
    query =
      from o in Orb,
      as: :o,
      where: o.initiator_id == ^user_id,
      preload: [:initiator],
      inner_lateral_join: c in subquery(
        from c in Phos.Comments.Comment,
        where: c.orb_id == parent_as(:o).id,
        select: %{count: count()}
      ),
      select_merge: %{comment_count: c.count}

    Repo.all(query, limit: 32)
    |> Enum.map(&(Map.put(&1, :comment_count, &1.comment_count)))
    |> Enum.filter(fn orb -> orb.active == true end)
  end

  @doc "Get list of orbs by given traits"
  @deprecated "Use filter_orbs_by_traits/2 instead which is more cleaner api with paginated response"
  def get_orbs_by_trait(trait), do: filter_orbs_by_traits(trait, limit: 8) |> Map.get(:data, [])

  def get_orb_by_trait_geo(geohashes, traits, options \\ [])
  def get_orb_by_trait_geo(geohashes, trait, options) when is_list(geohashes) do
    limit =  Keyword.get(options, :limit, 8)
    offset = Keyword.get(options, :offset, 0)
    query = from p in Phos.Action.Orb_Location,
      preload: [:orbs],
      where: p.location_id in ^geohashes,
      join: o in assoc(p, :orbs) ,
      where: fragment("? @> ?", o.traits, ^trait),
      limit: ^limit,
      offset: ^offset

    Repo.all(query)
  end
  def get_orb_by_trait_geo(geohash, trait, options), do: get_orb_by_trait_geo(geohash, [trait], options)

  #   @doc """
  #   Creates a orb.

  #   ## Examples

  #       iex> create_orb(%{field: value})
  #       {:ok, %Orb{}}

  #       iex> create_orb(%{field: bad_value})
  #       {:error, %Ecto.Changeset{}}

  #   """

  def create_orb(attrs \\ %{}) do
    %Orb{}
    |> Orb.changeset(attrs)
    |> Repo.insert()
    |> case do
         {:ok, orb} = data ->
           orb = orb |> Repo.preload([:initiator])
           spawn(fn ->
             experimental_notify(orb)
           end)
           #spawn(fn -> user_feeds_publisher(orb) end)
           data
         err -> err
       end
  end

  def admin_create_orb(attrs \\ %{}) do
    %Orb{}
    |> Orb.admin_changeset(attrs)
    |> Repo.insert()
    |> case do
         {:ok, orb} = data ->
           orb = orb |> Repo.preload([:initiator])
           spawn(fn ->
             unless(Enum.member?(orb.traits, "mirage")) do
               experimental_notify(orb)
             end
             #spawn(fn -> user_feeds_publisher(orb) end)
           end)
           data
         err -> err
       end
  end

  # defp user_feeds_publisher(%{initiator_id: user_id} = orb) do
  #   Phos.Folk.friends_lite(user_id)
  #   |> Enum.each(fn user_id ->
  #     # spawn(fn -> Phos.Cache.delete({Phos.Users.User, :feeds, user_id}) end)
  #     spawn(fn -> Phos.PubSub.publish(orb, {:feeds, "new"}, "userfeed:#{user_id}") end)
  #   end)
  # end

  def create_orb_and_publish(attrs \\ %{})
  def create_orb_and_publish(list) when is_list(list) do
    list
    |> Enum.map(fn data ->
      case create_orb_and_publish(data) do
        {:ok, orb} -> orb
        err -> err
      end
    end)
  end

  def create_orb_and_publish(attrs) do
    case admin_create_orb(attrs) do
      {:ok, orb} ->
        orb = orb |> Repo.preload([:locations])
        orb_loc_publisher(orb, :genesis, orb.locations)
        {:ok, orb}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}

    end
  end


  #   @doc """
  #   Updates a orb.

  #   ## Examples

  #       iex> update_orb(orb, %{field: new_value})
  #       {:ok, %Orb{}}

  #       iex> update_orb(orb, %{field: bad_value})
  #       {:error, %Ecto.Changeset{}}

  #   """
  def update_orb(%Orb{} = orb, attrs) do
    orb
    |> Orb.update_changeset(attrs)
    |> Repo.update()
  end

  def update_admin_orb(%Orb{} = orb, attrs) do
    orb
    |> Orb.admin_changeset(attrs)
    |> Repo.update()
  end

  #   @doc """
  #   Updates a orb.

  #   ## Examples

  #       iex> update_orb!(%{field: value})
  #       %Orb{}

  #       iex> Need to Catch error state

  #   """

  def update_orb!(%Orb{} = orb, attrs) do
    orb
    |> Orb.update_changeset(attrs)
    |> Repo.update!()
    |> Repo.preload([:initiator, :locations])
  end

  #   @doc """
  #   Deletes a orb.

  #   ## Examples

  #       iex> delete_orb(orb)
  #       {:ok, %Orb{}}

  #       iex> delete_orb(orb)
  #       {:error, %Ecto.Changeset{}}

  #   """
  def delete_orb(%Orb{} = orb) do
    from(o in Phos.Comments.Comment,
      as: :o,
      where: o.orb_id == ^orb.id)
    |> Phos.Repo.all()
    |> Enum.map(fn com ->
      from(o in Phos.Comments.Comment,
        as: :o,
        where: o.parent_id == ^com.id
      )
      |> Phos.Repo.all()
      |> Enum.map(fn comcom -> Phos.Comments.delete_comment(comcom) end)

      Phos.Comments.delete_comment(com) end)

    from(o in Phos.Message.Memory,
      as: :o,
      where: o.orb_subject_id == ^orb.id
    )
    |> Phos.Repo.all()
    |> Enum.map(fn mem -> Phos.Message.update_memory(mem, %{orb_subject_id: nil})
    end)

    Repo.delete(orb)
  end

  def admin_delete_orb(%Orb{} = orb) do
    from(o in Phos.Comments.Comment,
      as: :o,
      where: o.orb_id == ^orb.id)
    |> Phos.Repo.all()
    |> Enum.map(fn com ->
      from(o in Phos.Comments.Comment,
        as: :o,
        where: o.parent_id == ^com.id
      )
      |> Phos.Repo.all()
      |> Enum.map(fn comcom -> Phos.Comments.delete_comment(comcom) end)

      Phos.Comments.delete_comment(com) end)

    from(o in Phos.Message.Memory,
      as: :o,
      where: o.orb_subject_id == ^orb.id
    )
    |> Phos.Repo.all()
    |> Enum.map(fn mem -> Phos.Message.update_memory(mem, %{orb_subject_id: nil})
    end)


    Repo.delete(orb)
  end

  #   @doc """
  #   Returns an `%Ecto.Changeset{}` for tracking orb changes.

  #   ## Examples

  #       iex> change_orb(orb)
  #       %Ecto.Changeset{data: %Orb{}}

  #   """
  def change_orb(%Orb{} = orb, attrs \\ %{}) do
    Orb.changeset(orb, attrs)
  end

  defp orb_loc_publisher(orb, event, to_locations) do
    to_locations |> Enum.map(fn loc-> Phos.PubSub.publish(%{orb | topic: loc.id}, {:orb, event}, loc_topic(loc.id)) end)
  end

  defp loc_topic(hash) when is_integer(hash), do: "LOC.#{hash}"

  # Notion Actions

  def import_today_orb_from_notion do
    case Phos.External.Notion.today_post() do
      data when is_list(data) -> notion_importer(data)
      _ -> {:error, "Error fetching data from notion"}
    end
  end

  def import_platform_notification do
    case Phos.External.Notion.platform_notification() do
      data when is_list(data) -> notion_platform_importer(data)
      _ -> {:error, "Error fetching data from notion"}
    end
  end

  defp notion_importer(data) when is_list(data), do: Enum.map(data, &notion_parse_properties/1) |> List.flatten()
  defp notion_importer(_), do: []

  defp notion_platform_importer(data) when is_list(data) do
    Enum.map(data, &notion_platform_parse_properties/1)
    |> List.flatten()
    |> Enum.reduce([], fn data, acc ->
      [Enum.map(data, fn {k, v} -> {String.to_atom(k), v} end) |> Enum.into(%{}) | acc]
    end)
  end
  defp notion_platform_importer(_), do: []

  defp notion_get_values(%{"type" => "date", "date" => data}), do: data
  defp notion_get_values(%{"type" => "select", "select" => data}) when is_map(data), do: Map.get(data, "name")
  defp notion_get_values(%{"type" => "select", "select" => data}), do: data
  defp notion_get_values(%{"type" => "multi_select", "multi_select" => data}), do: Enum.map(data, fn d -> Map.get(d, "name") end)
  defp notion_get_values(%{"type" => "files", "files" => files}) when is_list(files) and length(files) > 0, do: List.first(files)["file"]["url"]
  defp notion_get_values(%{"type" => "url", "url" => link}), do: link
  defp notion_get_values(%{"type" => type} = data), do: notion_get_values(Map.get(data, type))
  defp notion_get_values(%{"content" => data}) when data == "" , do: nil
  defp notion_get_values(%{"content" => data}), do: data
  defp notion_get_values(data) when is_boolean(data), do: data
  defp notion_get_values(data) when is_list(data) and length(data) > 0, do: Enum.reduce(data, "", fn val, acc -> Kernel.<>(acc, notion_get_values(val)) end)
  defp notion_get_values(_), do: nil

  defp notion_parse_properties(%{"properties" => %{"Type" => type, "Regions" => region} = properties}) do
    sectors = Phos.External.Sector.get()
    case notion_get_values(type) do
      "all_regional" -> Enum.map(sectors, &orb_imported_detail(&1, properties))
      "some_regional" ->
        keys = notion_get_values(region) |> String.split(",") |> Enum.map(&String.trim/1)
        sectors
        |> Map.take(keys)
        |> Enum.map(&orb_imported_detail(&1, properties))
      "local" -> orb_local_imported_detail(properties)
      _ -> []
    end
  end

  defp notion_platform_parse_properties(%{"properties" => properties, "id" => id}) do
  Enum.reduce(properties, %{}, fn {k, v}, acc ->
    key = String.downcase(k) |> String.replace(" ", "_")
    value = notion_get_values(v)
    case key do
      "time_condition" -> Map.put(acc, key, notion_platform_time(value))
      "name" -> Map.merge(acc, %{
        "id" => id,
        "name" => value
      })
      k when k in ["id", "type"] -> acc
      _ -> Map.put(acc, key, value)
    end end)
  end

  defp notion_platform_time(%{"start" => <<_date::bytes-size(10)>> <> "T" <> _rest = date}) do
    case Timex.parse(date, "{RFC3339}") do
      {:ok, h} -> h
      _ -> notion_platform_time(nil)
    end
  end
  defp notion_platform_time(%{"start" => start_date}) do
    tz = decide_timezone("SGD")
    case Timex.parse(start_date, "{YYYY}-{0M}-{0D}") do
      {:ok, h} -> Timex.Timezone.convert(h, tz)
      _ -> notion_platform_time(nil)
    end
  end
  defp notion_platform_time(_time), do: DateTime.now!("Asia/Singapore")

  defp decide_timezone("SGD"), do: Timex.timezone("Asia/Singapore", {2022, 1, 1})
  defp decide_timezone(_), do: Timex.Timezone.local()

  defp orb_imported_detail({name, hashes} = sector, %{"Title" => title, "Radius" => radius, "Location" => location} = properties) do
    traits = Map.get(properties, "Traits", %{}) |> notion_get_values()
    default_orb_populator(sector, properties)
    |> Map.merge(%{
          where: notion_get_values(location) |> String.replace("[town]", name),
          title: notion_get_values(title) |> String.replace("[town]", name),
          geolocation: %{ live: live_location_populator(hashes, radius) },
          traits: traits
                 })
  end

  defp orb_imported_detail({name, hashes} = sector, %{"Inside Title" => inside_title, "Outside Title" => outer_title, "Location" => location, "Radius" => radius} = properties) do
    traits = Map.get(properties, "Traits", %{}) |> notion_get_values()
    default_orb_populator(sector, properties)
    |> Map.merge(%{
          where: notion_get_values(location) |> String.replace("[town]", name),
          title: notion_get_values(inside_title) |> String.replace("[town]", name),
          outer_title: notion_get_values(outer_title) |> String.replace("[town]", name),
          geolocation: %{ live: live_location_populator(hashes, radius)},
          traits: traits
                 })
  end

  defp orb_local_imported_detail(%{"Inside Title" => inside_title, "Coordinate" => coordinate, "Location" => location, "Info" => info, "Radius" => radius} = properties) do
    name = notion_get_values(info)
    traits = Map.get(properties, "Traits", %{}) |> notion_get_values()
    title = Map.get(properties, "Title", %{}) |> notion_get_values()
    default_orb_populator({ name, nil}, properties)
    |> Map.merge(%{
          where: notion_get_values(location) || "" |> String.replace("[town]", name),
          title: (if is_nil(notion_get_values(inside_title)), do: title, else: notion_get_values(inside_title)),
          geolocation: %{
            live: %{
              latlon: %{
                lat: latlong_converter(coordinate, 0),
                lon: latlong_converter(coordinate, 1)
              },
              target: notion_get_values(radius) |> String.trim() |> String.to_integer()
            }
          },
          traits: traits
                 })
  end

  defp default_orb_populator({name, _hashes}, %{"Info" => info,
                                                "Inside Image" => inside,
                                                "Outside Image" => outside,
                                                "Inside Image Low" => il,
                                                "Outside Image Low" => ol,
                                                "Done" => done,
                                                "Initiator Username" => initiator} = prop) do
    expires_in = 4 * 7 * 24 * 60 * 60 ## TODO let it be selected in Admin View instead
    %{
      id: Ecto.UUID.generate(),
      username: notion_get_values(initiator),
      expires_in: expires_in,
      info: (unless is_nil(notion_get_values(info)), do: notion_get_values(info) |> String.replace("[town]", name)),
      done: notion_get_values(done),
      initiator: Phos.Users.get_user_by_username(notion_get_values(initiator) || ""),
      media: true,
      inside: notion_get_values(inside),
      outside: notion_get_values(outside),
      inside_low: notion_get_values(il),
      outside_low: notion_get_values(ol),
      ext_link: %{
        name: (unless is_nil(notion_get_values(prop["External Message"])), do: notion_get_values(prop["External Message"])),
        url: (unless is_nil(notion_get_values(prop["External URL"])), do: notion_get_values(prop["External URL"])),
        referral: (unless is_nil(notion_get_values(prop["External Referral Code"])), do: notion_get_values(prop["External Referral Code"]))
      }
    }
  end

  defp live_location_populator(hashes, radius) do
    %{
      populate: true,
      geohashes: hashes,
      target: notion_get_values(radius) |> String.trim() |> String.to_integer(),
      geolock: true,
    }
  end

  defp latlong_converter(coordinate, position) when is_binary(coordinate) do
    coordinate
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.replace(&1, "[town]", "0.0"))
    |> Enum.map(&String.to_float/1)
    |> Enum.at(position)
  end
  defp latlong_converter(coordinate, position), do: notion_get_values(coordinate) |> latlong_converter(position)

  def create_personal_orb(attrs \\ %{}) do
    attrs
    |> Map.put("traits", ["personal"])
    |> create_orb()
  end

  def subscribe_to_orb(%Orb{id: _id} = _orb, %Phos.Users.User{} = _user) do
    # topic = "ORB.#{id}"
    ## TODO SUB User Topic to Orb
    #token = Map.get(user, :private_profile, %{}) |> Map.get(:user_token)
    #Phos.Notification.subscribe(token, topic)
  end

  def filter_orbs_by_traits(traits, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    limit = Keyword.get(opts, :limit, 10)
    sort_attribute = Keyword.get(opts, :sort_attribute, :inserted_at)
    query = from p in __MODULE__.Orb, preload: [:initiator], where: fragment("? @> ?", p.traits, ^traits)

    Repo.Paginated.all(query, page, sort_attribute, limit)
  end

  def reorb(user_id, orb_id, message \\ "")
  def reorb(%Phos.Users.User{} = user, %Orb{} = orb, message), do: reorb(user.id, orb.id, message)
  def reorb(user_id, orb_id, message) when is_binary(user_id) and is_binary(orb_id) do
    id = Ecto.UUID.generate()
    orb = get_orb!(orb_id)
    message = if message == "", do: orb.title, else: message
    path = case orb.path do
      %{labels: []} -> Phos.Utility.Encoder.encode_lpath(id, orb.id)
      %{labels: labels} -> Phos.Utility.Encoder.encode_lpath(id, labels)
      _ -> Phos.Utility.Encoder.encode_lpath(id, orb.id)
    end

    attrs =
      Map.from_struct(orb)
      |> Map.take(~W(active central_geohash extinguish media)a)
      |> Map.merge(%{
        id: id,
        title: message,
        path: path,
        parent_id: orb_id,
        initiator_id: user_id,
        traits: ["reorb" | Map.get(orb, :traits, [])],
      })

    create_orb(attrs)
  end

  def experimental_notify(orb) do
    geonotifiers =
      notifiers_by_geohashes([orb.central_geohash])
      |> Enum.map(fn n -> n && Map.get(n, :fcm_token, nil) end)
      |> MapSet.new()
      |> MapSet.delete(get_in(orb.initiator, [Access.key(:integrations, %{}), Access.key(:fcm_token, nil)]))
      |> tap(fn batch ->
      Phos.PlatformNotification.Batch.push(batch,
        title: "#{orb.initiator.username} from Around Me",
        body: orb.title,
        initiator_id: orb.initiator_id,
        action_path: "/orbland/orbs/#{orb.id}",
        cluster_id: "loc_orb")
    end)


      # allynotifiers
      Phos.Folk.notifiers_by_friends(orb.initiator_id)
      |> Enum.map(fn n -> n && Map.get(n, :fcm_token, nil) end)
      |> MapSet.new()
      |> MapSet.difference(geonotifiers)
      |> MapSet.delete(get_in(orb.initiator, [Access.key(:integrations, %{}), Access.key(:fcm_token, nil)]))
      |> Phos.PlatformNotification.Batch.push(
        title: "#{orb.initiator.username} from Following",
      body: orb.title,
      initiator_id: orb.initiator_id,
      action_path: "/orbland/orbs/#{orb.id}",
      cluster_id: "folk_orb")
  end
end
