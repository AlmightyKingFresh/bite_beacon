defmodule BiteBeacon.FaciltiesTest do
  @moduledoc """
  Test suite for Facilities context
  """

  use BiteBeacon.DataCase, async: true

  import BiteBeacon.Factory

  alias BiteBeacon.Facilities.{Facilities, Facility, Vendor}
  alias BiteBeacon.Repo

  describe "Facility changeset functions" do
    test "valid registration given to registration_changest/1 works properly " do
      %{id: vendor_id} = insert(:vendor)

      changeset =
        Facility.registration_changeset(%Facility{}, %{
          vendor_id: vendor_id,
          name: "Dana's Truck",
          type: "Truck"
        })

      assert changeset.valid?
    end

    test "missing vendor_id fails registration_changeset/1" do
      changeset =
        Facility.registration_changeset(%Facility{}, %{
          name: "Dana's Truck",
          type: "Truck"
        })

      assert errors_on(changeset) == %{vendor_id: ["can't be blank"]}
    end

    test "missing name fails registration_changeset/1" do
      %{id: vendor_id} = insert(:vendor)

      changeset =
        Facility.registration_changeset(%Facility{}, %{
          type: "Truck",
          vendor_id: vendor_id
        })

      assert errors_on(changeset) == %{name: ["can't be blank"]}
    end

    test "bad type fails registration_changeset/1" do
      %{id: vendor_id} = insert(:vendor)

      changeset =
        Facility.registration_changeset(%Facility{}, %{
          name: "Naruto Udon!",
          vendor_id: vendor_id,
          type: "picnic basket"
        })

      assert errors_on(changeset) == %{type: ["is invalid"]}
    end
  end
end
