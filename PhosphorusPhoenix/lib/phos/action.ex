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
  def get_orb!(id), do: Repo.get!(Orb, id)
  def get_orb_by_fyr(id), do: Repo.get_by(Phos.Users.User, fyr_id: id)

  def get_orbs_by_geohashes(ids) do
    query =
      Orb_Location
      |> where([e], e.location_id in ^ids)
      |> preload(orbs: :users)
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
    multi =
      Multi.new()
      |> Multi.insert(:insert_orb, %Orb{} |> Orb.changeset(attrs))
      |> Multi.insert_all(:insert_locations, Location, parse_locations(attrs), on_conflict: :nothing, conflict_target: :id)
      |> Multi.insert_all(:insert_orb_locations, Orb_Location, fn %{insert_orb: orb} ->
        parse_locations(orb.id, attrs)
      end)

    case (Repo.transaction(multi)) do
      {:ok, results} ->
        IO.puts "Ecto Multi Success"
        {:ok, results.insert_orb}
      {:error, :insert_orb, changeset, _changes} ->
        {:error, changeset}
      {:error, :insert_locations, changeset, _changes} ->
        {:error, changeset}
      {:error, :insert_orb_locations, changeset, _changes} ->
        {:error, changeset}
    end
   end

  defp parse_locations(orb_id, attrs) do
    case attrs do
      %{"geolocation" => location_list} ->
        timestamp = NaiveDateTime.utc_now()
        |> NaiveDateTime.truncate(:second)

        maps = Enum.map(location_list, &%{
          orb_id: orb_id,
          location_id: &1,
          inserted_at: timestamp,
          updated_at: timestamp
        })

        %{geolocation: location_list} ->
          timestamp = NaiveDateTime.utc_now()
          |> NaiveDateTime.truncate(:second)

          maps = Enum.map(location_list, &%{
            orb_id: orb_id,
            location_id: &1,
            inserted_at: timestamp,
            updated_at: timestamp
          })

        maps
      %{} ->
        IO.puts "missing geolocation"
        []
    end
  end

  defp parse_locations(attrs) do
    case attrs do
      %{"geolocation" => location_list} ->
        timestamp = NaiveDateTime.utc_now()
        |> NaiveDateTime.truncate(:second)

        maps = Enum.map(location_list, &%{
          id: &1,
          inserted_at: timestamp,
          updated_at: timestamp
        })

        %{geolocation: location_list} ->
          timestamp = NaiveDateTime.utc_now()
          |> NaiveDateTime.truncate(:second)

          maps = Enum.map(location_list, &%{
            id: &1,
            inserted_at: timestamp,
            updated_at: timestamp
          })

        maps
      %{} ->
        IO.puts "missing geolocation"
        []
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
    |> Orb.changeset(attrs)
    |> Repo.update()
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
end
