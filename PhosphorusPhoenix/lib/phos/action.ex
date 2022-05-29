defmodule Phos.Action do
  @moduledoc """
  The Action context.
  """

  import Ecto.Query, warn: false
  alias Phos.Repo
  alias Phos.Action.{Orb, Location, Orb_Location}
  alias Ecto.Multi

  @doc """
  Returns the list of orbs.

  ## Examples

      iex> list_orbs()
      [%Orb{}, ...]

  """
  def list_orbs do
    Repo.all(Orb)
    #|> Repo.preload(:locations)
    #|> Repo.preload(:payload)
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
  def get_orbs_by_geohash(id) do
    query =
      Orb_Location
      |> where([e], e.location_id == ^id)
      |> preload(:orbs)

    Repo.all(query, limit: 32)
  end

#   @doc """
#   Creates a orb.

#   ## Examples

#       iex> create_orb(%{field: value})
#       {:ok, %Orb{}}

#       iex> create_orb(%{field: bad_value})
#       {:error, %Ecto.Changeset{}}

#   """

  # Phos.Action.create_orb(%{"geolocation" => [614268985908658175, 614268985470353407, 614268985912852479, 614268985900269567, 614268985910755327, 614268985652805631, 614268985466159103], "payload"=> %{"image" => "S3 path", "time" => 1653534012, "tip" => "bbt", "info" => "more more text"}, "title" => "sembawang NICE food", "extinguish" => NaiveDateTime.utc_now()})
  # Phos.Action.create_orb(%{"geolocation" => [623276184907743231, 623276184907710463, 623276184907579391, 623276184907612159, 623276184908038143, 623276184908988415, 623276184908955647], "payload"=> %{"image" => "S3 path", "time" => 1653534012, "tip" => "bbt", "info" => "more more text"}, "title" => "sembawang NICE food 2", "extinguish" => NaiveDateTime.utc_now()})
  # Phos.Action.create_orb(%{"geolocation" => [614269017678413823, 614269017676316671, 614269017682608127, 614269018120912895, 614269017865060351, 614269017873448959, 614269017686802431], "payload"=> %{"image" => "S3 path", "time" => 1653534012, "tip" => "bbt", "info" => "more more text"}, "title" => "simpang NICE food", "extinguish" => NaiveDateTime.utc_now()})
  # Phos.Action.create_orb(%{"geolocation" => [614269017680510975, 614269017661636607, 614269018104135679, 614269018106232831, 614269017682608127, 614269017676316671, 614269017688899583], "payload"=> %{"image" => "S3 path", "time" => 1653534012, "tip" => "bbt", "info" => "more more text"}, "title" => "sutd NICE food", "extinguish" => NaiveDateTime.utc_now()})
  # Phos.Action.create_orb(%{"geolocation" => [614268613639012351, 614268613704024063, 614268613643206655, 614268613630623743, 614268613641109503, 614268613718704127, 614268613699829759], "payload"=> %{"image" => "S3 path", "time" => 1653534012, "tip" => "bbt", "info" => "more more text"}, "title" => "bp rock", "extinguish" => NaiveDateTime.utc_now()})

  def create_orb(attrs \\ %{}) do
    multi =
      Multi.new()
      |> Multi.insert(:insert_orb, %Orb{} |> Orb.changeset(attrs))
      |> Multi.insert_all(:insert_locations, Location, parse_locations(attrs), on_conflict: :nothing, conflict_target: :id)
      |> Multi.insert_all(:insert_orb_locations, Orb_Location, fn %{insert_orb: orb} ->
        parse_locations(orb.id, attrs)
      end)

    case (Repo.transaction(multi)) do
      {:ok, _results} ->
        IO.puts "Ecto Multi Success"
      {:error, :insert_orb, changeset, _changes} ->
        IO.puts "Orb insert failed"
        IO.inspect changeset.errors
      {:error, :insert_locations, changeset, _changes} ->
        IO.puts "Location insert failed"
        IO.inspect changeset.errors
      {:error, :insert_orb_locations, changeset, _changes} ->
        IO.puts "Orb_Location insert failed"
        IO.inspect changeset.errors
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

        maps
      %{} ->
        IO.puts "missing geolocation"
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

        maps
      %{} ->
        IO.puts "missing geolocation"
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
