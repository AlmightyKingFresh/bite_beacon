defmodule BiteBeacon.Food_FacilitiesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BiteBeacon.Food_Facilities` context.
  """

  @doc """
  Generate a facility.
  """
  def facility_fixture(attrs \\ %{}) do
    {:ok, facility} =
      attrs
      |> Enum.into(%{})
      |> BiteBeacon.Food_Facilities.create_facility()

    facility
  end
end
