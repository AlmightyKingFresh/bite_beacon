defmodule BiteBeacon.Food_FacilitiesTest do
  use BiteBeacon.DataCase

  alias BiteBeacon.Food_Facilities

  describe "facilities" do
    alias BiteBeacon.Food_Facilities.Facility

    import BiteBeacon.Food_FacilitiesFixtures

    @invalid_attrs %{}

    test "list_facilities/0 returns all facilities" do
      facility = facility_fixture()
      assert Food_Facilities.list_facilities() == [facility]
    end

    test "get_facility!/1 returns the facility with given id" do
      facility = facility_fixture()
      assert Food_Facilities.get_facility!(facility.id) == facility
    end

    test "create_facility/1 with valid data creates a facility" do
      valid_attrs = %{}

      assert {:ok, %Facility{} = facility} = Food_Facilities.create_facility(valid_attrs)
    end

    test "create_facility/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Food_Facilities.create_facility(@invalid_attrs)
    end

    test "update_facility/2 with valid data updates the facility" do
      facility = facility_fixture()
      update_attrs = %{}

      assert {:ok, %Facility{} = facility} =
               Food_Facilities.update_facility(facility, update_attrs)
    end

    test "update_facility/2 with invalid data returns error changeset" do
      facility = facility_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Food_Facilities.update_facility(facility, @invalid_attrs)

      assert facility == Food_Facilities.get_facility!(facility.id)
    end

    test "delete_facility/1 deletes the facility" do
      facility = facility_fixture()
      assert {:ok, %Facility{}} = Food_Facilities.delete_facility(facility)
      assert_raise Ecto.NoResultsError, fn -> Food_Facilities.get_facility!(facility.id) end
    end

    test "change_facility/1 returns a facility changeset" do
      facility = facility_fixture()
      assert %Ecto.Changeset{} = Food_Facilities.change_facility(facility)
    end
  end
end
