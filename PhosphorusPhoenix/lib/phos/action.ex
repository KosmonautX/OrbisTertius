defmodule Phos.Action do
  @moduledoc """
  The Action context.
  """

  import Ecto.Query, warn: false
  alias Phos.Repo

  alias Phos.Action.Orb

  @doc """
  Returns the list of orbs.

  ## Examples

      iex> list_orbs()
      [%Orb{}, ...]

  """
  def list_orbs do
    Repo.all(Orb)
  end

  @doc """
  Gets a single orb.

  Raises `Ecto.NoResultsError` if the Orb does not exist.

  ## Examples

      iex> get_orb!(123)
      %Orb{}

      iex> get_orb!(456)
      ** (Ecto.NoResultsError)

  """
  def get_orb!(id), do: Repo.get!(Orb, id)

  @doc """
  Creates a orb.

  ## Examples

      iex> create_orb(%{field: value})
      {:ok, %Orb{}}

      iex> create_orb(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_orb(attrs \\ %{}) do
    %Orb{}
    |> Orb.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a orb.

  ## Examples

      iex> update_orb(orb, %{field: new_value})
      {:ok, %Orb{}}

      iex> update_orb(orb, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_orb(%Orb{} = orb, attrs) do
    orb
    |> Orb.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a orb.

  ## Examples

      iex> delete_orb(orb)
      {:ok, %Orb{}}

      iex> delete_orb(orb)
      {:error, %Ecto.Changeset{}}

  """
  def delete_orb(%Orb{} = orb) do
    Repo.delete(orb)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking orb changes.

  ## Examples

      iex> change_orb(orb)
      %Ecto.Changeset{data: %Orb{}}

  """
  def change_orb(%Orb{} = orb, attrs \\ %{}) do
    Orb.changeset(orb, attrs)
  end
end
