defmodule BiteBeacon.FaciltiesTest do
  @moduledoc """
  Test suite for Facilities context
  """

  use BiteBeacon.DataCase, async: true

  import BiteBeacon.Factory

  alias BiteBeacon.Facilities.{Facilities, Facility}
  alias BiteBeacon.Repo
  alias BiteBeacon.Vendors.Vendor

  describe "Facility changeset functions" do
    test "valid registration given to registration_changest/1 works properly " do
      %{id: vendor_id} = insert(:vendor)

      changeset =
        Facility.registration_changeset(%Facility{}, %{
          vendor_id: vendor_id,
          name: "Dana's Truck",
          type: "Truck",
          id: generate_facility_id()
        })

      assert changeset.valid?
    end

    test "missing vendor_id fails registration_changeset/1" do
      changeset =
        Facility.registration_changeset(%Facility{}, %{
          name: "Dana's Truck",
          type: "Truck",
          id: generate_facility_id()
        })

      assert errors_on(changeset) == %{vendor_id: ["can't be blank"]}
    end

    test "missing name fails registration_changeset/1" do
      %{id: vendor_id} = insert(:vendor)

      changeset =
        Facility.registration_changeset(%Facility{}, %{
          type: "Truck",
          vendor_id: vendor_id,
          id: generate_facility_id()
        })

      assert errors_on(changeset) == %{name: ["can't be blank"]}
    end

    test "missing facility_id fails registration changeset" do
      %{id: vendor_id} = insert(:vendor)

      changeset =
        Facility.registration_changeset(%Facility{}, %{
          name: "Dana's Truck",
          type: "Truck",
          vendor_id: vendor_id
        })

      assert errors_on(changeset) == %{id: ["can't be blank"]}
    end

    test "bad type fails registration_changeset/1" do
      %{id: vendor_id} = insert(:vendor)

      changeset =
        Facility.registration_changeset(%Facility{}, %{
          name: "Naruto Udon!",
          vendor_id: vendor_id,
          type: "picnic basket",
          id: generate_facility_id()
        })

      assert errors_on(changeset) == %{type: ["is invalid"]}
    end

    test "cuisine at max length (500) passes registration_changeset/1" do
      %{id: vendor_id} = insert(:vendor)
      cuisine = String.duplicate("a", 500)

      changeset =
        Facility.registration_changeset(%Facility{}, %{
          vendor_id: vendor_id,
          name: "Dana's Truck",
          type: "Truck",
          id: generate_facility_id(),
          cuisine: cuisine
        })

      assert changeset.valid?
    end

    test "cuisine over max length (501) fails registration_changeset/1" do
      %{id: vendor_id} = insert(:vendor)
      cuisine = String.duplicate("a", 501)

      changeset =
        Facility.registration_changeset(%Facility{}, %{
          vendor_id: vendor_id,
          name: "Dana's Truck",
          type: "Truck",
          id: generate_facility_id(),
          cuisine: cuisine
        })

      refute changeset.valid?
    end
  end

  describe "Facilities CRUD" do
    setup do
      %Vendor{id: vendor1_id} = vendor1 = insert(:vendor)
      %Vendor{id: vendor2_id} = vendor2 = insert(:vendor)
      facility1 = insert(:facility, vendor_id: vendor1_id)
      facility2 = insert(:facility, vendor_id: vendor2_id)
      facility3 = insert(:facility, vendor_id: vendor1_id)

      %{
        vendor1: vendor1,
        vendor2: vendor2,
        facility1: facility1,
        facility2: facility2,
        faciltiy3: facility3
      }
    end

    test "list_facilites/0 returns all facilties", %{
      facility1: facility1,
      facility2: facility2,
      faciltiy3: facility3
    } do
      facilities = Facilities.list_facilities()
      assert facility1 in facilities
      assert facility2 in facilities
      assert facility3 in facilities
    end

    test " list_facilities/0 returns nothing if table is empty" do
      Repo.delete_all(Facility)
      assert Facilities.list_facilities() == []
    end

    test "get_facility/1 fetches facility by facility id", %{facility1: facility1} do
      %{id: facility_id} = facility1
      assert facility1 == Facilities.get_facility(facility_id)
    end

    test "get_facility/1 returns nil if id is not in table" do
      assert Facilities.get_facility(1_234_567) == nil
    end

    test "list_facilites_by_vendor/1 returns all facilites with given vendor_id", %{
      vendor1: vendor1,
      facility1: facility1,
      faciltiy3: facility3
    } do
      %{id: vendor_id} = vendor1
      facilities = Facilities.list_facilities_by_vendor_id(vendor_id)

      assert facility1 in facilities
      assert facility3 in facilities
    end

    test "list_facilites_by_vendor/1 returns empty list if no facilties exist in table with corresponding vendor_id",
         %{vendor1: vendor1} do
      Repo.delete_all(Facility)
      %{id: vendor_id} = vendor1
      assert [] == Facilities.list_facilities_by_vendor_id(vendor_id)
    end

    test "list_facilities_by_name/1 returns facilities with given name", %{facility1: facility1} do
      %{name: facility_name} = facility1
      assert [facility1] == Facilities.list_facilities_by_name(facility_name)
    end

    test "list_facilities_by_name/1 returns empty list when given name isn't in table" do
      assert [] == Facilities.list_facilities_by_name("Gracie's Cakes")
    end

    test "insert_facility/1 inserts given facility with existing vendor and required attrs", %{
      vendor2: vendor2
    } do
      %{id: vendor_id} = vendor2
      facility_id = generate_facility_id()

      {:ok, facility} =
        Facilities.insert_facility(%{
          vendor_id: vendor_id,
          name: "Dana's Truck",
          type: "Truck",
          id: facility_id
        })

      assert Map.get(facility, :vendor_id) == vendor_id
      assert Map.get(facility, :name) == "Dana's Truck"
      assert Map.get(facility, :type) == "Truck"
      assert Map.get(facility, :id) == facility_id
    end

    test "update_facility/2 updates given facility only where changes are provided", %{
      facility1: facility1
    } do
      {:ok, facility} = Facilities.update_facility(facility1, %{name: "Updated Facility"})
      assert Map.get(facility, :name) == "Updated Facility"
      assert Map.get(facility, :type) == facility1.type
      assert Map.get(facility, :id) == facility1.id
    end

    test "update_facility/2 returns error when updating with invalid data", %{
      facility1: facility1
    } do
      {:error, changeset} = Facilities.update_facility(facility1, %{name: ""})
      assert errors_on(changeset) == %{name: ["can't be blank"]}
    end

    test "update_facility/2 fails with non-existent vendor", %{
      facility1: facility1
    } do
      {:error, changeset} =
        Facilities.update_facility(facility1, %{vendor_id: Ecto.UUID.generate()})

      assert errors_on(changeset) == %{vendor_id: ["does not exist"]}
    end

    test "delete_facility/1 deletes given facility leaves others untouched", %{
      facility1: facility1,
      facility2: facility2
    } do
      {:ok, deleted_facility} = Facilities.delete_facility(facility1)
      assert Map.get(deleted_facility, :id) == Map.get(facility1, :id)
      assert Repo.get(Facility, facility1.id) == nil
      assert Repo.get(Facility, facility2.id) != nil
    end

    test "delete_facility/1 returns error for non-existent facility" do
      facility = build(:facility)

      assert Facilities.delete_facility(facility) == {:error, :facility_not_found}
    end
  end
end
