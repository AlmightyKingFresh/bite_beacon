defmodule BiteBeacon.Facilities.Facilities do
  @moduledoc """
  The Facilities context.
  """

  import Ecto.Query, warn: false
  alias BiteBeacon.Repo

  alias BiteBeacon.Facilities.Facility

  @doc """
  Returns the list of facilities.

  ## Examples

      iex> list_facilities()
      [%Facility{}, ...]

  """
  def list_facilities do
    Repo.all(Facility)
  end

  @doc """
  Gets a single facility.

  Raises `Ecto.NoResultsError` if the Facility does not exist.

  ## Examples

      iex> get_facility!(123)
      %Facility{}

      iex> get_facility!(456)
      ** (Ecto.NoResultsError)

  """
  def get_facility!(id), do: Repo.get!(Facility, id)

  @doc """
  gets all facilities by vendor_id

  """
  def list_facilities_by_vendor_id(vendor_id) when is_binary(vendor_id) do
    Repo.all(from f in Facility, where: f.vendor_id == ^vendor_id)
  end

  @doc """
  gets facilities by name
  """
  def list_facilities_by_name(name) when is_binary(name) do
    Repo.all(from f in Facility, where: f.name == ^name)
  end

  def create_facility(attrs \\ %{}) do
    %Facility{}
    |> Facility.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a facility.

  ## Examples

      iex> update_facility(facility, %{field: new_value})
      {:ok, %Facility{}}

      iex> update_facility(facility, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_facility(%Facility{} = facility, attrs) do
    facility
    |> Facility.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a facility.

  ## Examples

      iex> delete_facility(facility)
      {:ok, %Facility{}}

      iex> delete_facility(facility)
      {:error, %Ecto.Changeset{}}

  """
  def delete_facility(%Facility{} = facility) do
    Repo.delete(facility)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking facility changes.

  ## Examples

      iex> change_facility(facility)
      %Ecto.Changeset{data: %Facility{}}

  """
  def change_facility(%Facility{} = facility, attrs \\ %{}) do
    Facility.changeset(facility, attrs)
  end
end
