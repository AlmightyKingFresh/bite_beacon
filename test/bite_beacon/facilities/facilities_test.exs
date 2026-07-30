defmodule BiteBeacon.FacilitiesTest do
  use BiteBeacon.DataCase

  alias BiteBeacon.Facilities.{Facility, Facilities}

  describe "facilities" do
    import BiteBeacon.FacilityFixtures

    @invalid_attrs %{}

    test "list_facilities/0 returns all facilities" do
      facility = facility_fixture()
      assert Facilities.list_facilities() == [facility]
    end

    test "get_facility!/1 returns the facility with given id" do
      facility = facility_fixture()
      assert Facilities.get_facility!(facility.id) == facility
    end

    test "create_facility/1 with valid data creates a facility" do
      valid_attrs = %{}

      assert {:ok, %Facility{} = facility} = Facilities.create_facility(valid_attrs)
    end

    test "create_facility/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Facilities.create_facility(@invalid_attrs)
    end

    test "update_facility/2 with valid data updates the facility" do
      facility = facility_fixture()
      update_attrs = %{}

      assert {:ok, %Facility{} = facility} =
               Facilities.update_facility(facility, update_attrs)
    end

    test "update_facility/2 with invalid data returns error changeset" do
      facility = facility_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Facilities.update_facility(facility, @invalid_attrs)

      assert facility == Facilities.get_facility!(facility.id)
    end

    test "delete_facility/1 deletes the facility" do
      facility = facility_fixture()
      assert {:ok, %Facility{}} = Facilities.delete_facility(facility)
      assert_raise Ecto.NoResultsError, fn -> Facilities.get_facility!(facility.id) end
    end

    test "change_facility/1 returns a facility changeset" do
      facility = facility_fixture()
      assert %Ecto.Changeset{} = Facilities.change_facility(facility)
    end
  end
end
