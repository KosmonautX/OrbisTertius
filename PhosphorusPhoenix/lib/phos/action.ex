defmodule Phos.Action do
  @moduledoc """
  The Action context.
  """

  import Ecto.Query, warn: false
  alias Phos.Repo
  alias Phos.Action.{Orb, Location, Orb_Payload, Orb_Location}

  alias Ecto.Multi

  @doc """
  Returns the list of orbs.

  ## Examples

      iex> list_orbs()
      [%Orb{}, ...]

  """
  def list_orbs do
    Repo.all(Orb)
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
    query = from o in Orb, preload: [:locations, :initiator], where: o.id == ^id, limit: 1
    case Repo.one(query) do
      %Orb{} = orb -> {:ok, orb}
      _ -> {:error, "Record not found"}
    end
  end
  def get_orb!(id), do: Repo.get!(Orb, id) |> Repo.preload([:locations, :initiator])
  def get_orb_by_fyr(id), do: Repo.get_by(Phos.Users.User, fyr_id: id)

  def list_all_active_orbs(options \\ []) do
    page = Keyword.get(options, :page, 1)
    offset = Keyword.get(options, :offset, 20)
    query = from o in Orb, where: o.active == true, preload: [:initiator], order_by: [desc: :inserted_at], limit: ^offset, offset: ^((page - 1) * offset)
    Repo.all(query)
  end

  def get_orbs_by_geohashes(ids) do
    query =
      Orb_Location
      |> where([e], e.location_id in ^ids)
      |> preload(orbs: :initiator)
      |> order_by(desc: :inserted_at)

    Repo.all(query, limit: 32)
    |> Enum.map(fn orb -> orb.orbs end)
  end

  def get_active_orbs_by_geohashes(ids) do
    query =
      Orb_Location
      |> where([e], e.location_id in ^ids)
      |> preload(:orbs)
      |> preload(:locations)
      |> order_by(desc: :inserted_at)

    Repo.all(query, limit: 32)
    |> Enum.map(fn orb -> orb.orbs end)
    |> Enum.filter(fn orb -> orb.active == true end)
  end

  def get_orbs_by_trait(trait) do
    query =
      from p in Phos.Action.Orb, where: fragment("? @> ?", p.traits, ^trait)

    Repo.all(query, limit: 8)
  end

  def get_orb_by_trait_geo(geohash, trait) do

    query = from p in Phos.Action.Orb_Location,
      where: p.location_id == ^geohash,
      join: o in assoc(p, :orbs) ,
      where: fragment("? @> ?", o.traits, ^trait)

    Repo.all(query |> preload(:orbs), limit: 8)
  end

#   @doc """
#   Creates a orb.

#   ## Examples

#       iex> create_orb(%{field: value})
#       {:ok, %Orb{}}

#       iex> create_orb(%{field: bad_value})
#       {:error, %Ecto.Changeset{}}

#   """

  def create_orb(attrs \\ %{}) do
    case attrs do
      %{"geolocation" => location_list} ->
        timestamp = NaiveDateTime.utc_now()
        |> NaiveDateTime.truncate(:second)

        maps = Enum.map(location_list, &%{
          id: &1,
          inserted_at: timestamp,
          updated_at: timestamp
        })

        Repo.insert_all(Location, maps, on_conflict: :nothing, conflict_target: :id)
        location_ids = Enum.map(maps, fn loc -> loc.id end)
        orb_locations_upsert(attrs, location_ids)

        _ ->
        %Orb{}
        |> Orb.changeset(attrs)
        |> Repo.insert()
    end
  end

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
    case create_orb(attrs) do
      {:ok, orb} ->
        orb_loc_publisher(orb, :genesis, orb.locations)
        {:ok, orb}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}

    end
  end

  def orb_locations_upsert(attrs, location_ids) when is_list(location_ids) do
    locations =
      Location
      |> where([location], location.id in ^location_ids)
      |> Repo.all()


    %Orb{} |> Orb.changeset(attrs) |> Repo.insert!() |> Repo.preload([:locations, :initiator])
    |> Orb.changeset_update_locations(locations)
    |> Repo.update()
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
    |> Orb.changeset(attrs)
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
    |> Orb.changeset_edit(attrs)
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

  def import_today_orb_from_notion do
    case Phos.External.Notion.today_post() do
      data when is_list(data) -> notion_importer(data)
      _ -> {:error, "Error fetching data from notion"}
    end
  end

  defp notion_importer(data) when is_list(data), do: Enum.map(data, &do_notion_import/1) |> List.flatten()
  defp notion_importer(_), do: []

  defp notion_get_values(%{"type" => "multi_select", "multi_select" => data}), do: Enum.map(data, fn d -> Map.get(d, "name") end)
  defp notion_get_values(%{"type" => type} = data), do: notion_get_values(Map.get(data, type))
  defp notion_get_values(%{"content" => data}), do: data
  defp notion_get_values(data) when is_boolean(data), do: data
  defp notion_get_values(data) when is_list(data) and length(data) > 0, do: Enum.reduce(data, "", fn val, acc -> Kernel.<>(acc, notion_get_values(val)) end)
  defp notion_get_values(_), do: "[town]"

  defp do_notion_import(%{"properties" => %{"Type" => type, "Regions" => region} = properties}) do
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

  defp orb_imported_detail({name, hashes} = sector, %{"Title" => title, "Radius" => radius} = properties) do
    traits = Map.get(properties, "Traits", %{}) |> notion_get_values()
    default_orb_populator(sector, properties)
    |> Map.merge(%{
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
      geolocation: %{ live: live_location_populator(hashes, radius) },
      traits: traits
    })
  end

  defp orb_local_imported_detail(%{"Inside Title" => inside_title, "Coordinate" => coordinate, "Location" => location, "Info" => info, "Radius" => radius} = properties) do
    name = notion_get_values(info)
    traits = Map.get(properties, "Traits", %{}) |> notion_get_values()
    title = Map.get(properties, "Title", %{}) |> notion_get_values()
    default_orb_populator({ name, nil}, properties)
    |> Map.merge(%{
      where: notion_get_values(location) |> String.replace("[town]", name),
      title: notion_get_values(inside_title) |> String.replace("[town]", title),
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

  defp default_orb_populator({name, _hashes}, %{"Info" => info, "Done" => done} = _properties) do
    expires_in = 4 * 7 * 24 * 60 * 60

    %{
      user_id: 1,
      username: "Administrator",
      user_media: true,
      expires_in: expires_in,
      info: notion_get_values(info) |> String.replace("[town]", name),
      done: notion_get_values(done),
      orb_nature: "01",
      media: true
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
end
