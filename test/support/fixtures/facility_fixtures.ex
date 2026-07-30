defmodule BiteBeacon.FacilityFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BiteBeacon.Facilities` context.
  """

  @doc """
  Generate a facility.
  """
  def facility_fixture(attrs \\ %{}) do
    {:ok, facility} =
      attrs
      |> Enum.into(%{})
      |> BiteBeacon.Facilities.Facilities.create_facility()

    facility
  end
end
