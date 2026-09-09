defmodule BiteBeacon.Facilities.Facilities do
  @moduledoc """
  The Facilities context.
  """

  import Ecto.Query, warn: false
  alias BiteBeacon.Repo

  alias BiteBeacon.Facilities.Facility

  @doc """
  Returns the list of facilities.
  """
  @spec list_facilities() :: [Facility.t()]
  def list_facilities do
    Repo.all(Facility)
  end

  @doc """
  Gets a single facility.
  """
  @spec get_facility(integer()) :: Facility.t() | nil
  def get_facility(id), do: Repo.get(Facility, id)

  @doc """
  gets all facilities by vendor_id

  """
  @spec list_facilities_by_vendor_id(Ecto.UUID.t()) :: [Facility.t()]
  def list_facilities_by_vendor_id(vendor_id) when is_binary(vendor_id) do
    Repo.all(from f in Facility, where: f.vendor_id == ^vendor_id)
  end

  @doc """
  gets facilities by name
  """
  @spec list_facilities_by_name(String.t()) :: [Facility.t()]
  def list_facilities_by_name(name) when is_binary(name) do
    Repo.all(from f in Facility, where: f.name == ^name)
  end

  @spec insert_facility(map()) :: {:ok, Facility.t()} | {:error, Ecto.Changeset.t()}
  def insert_facility(attrs) do
    %Facility{}
    |> Facility.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a facility.
  """
  @spec update_facility(Facility.t(), map()) :: {:ok, Facility.t()} | {:error, Ecto.Changeset.t()}
  def update_facility(%Facility{} = facility, attrs) do
    facility
    |> Facility.registration_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a facility.
  """
  @spec delete_facility(Facility.t()) :: {:ok, Facility.t()} | {:error, :facility_not_found}
  def delete_facility(%Facility{} = facility) do
    Repo.delete(facility)
  rescue
    Ecto.StaleEntryError ->
      {:error, :facility_not_found}
  end
end
