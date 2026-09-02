defmodule BiteBeacon.Reviews.ReviewsTests do
  @moduledoc """
  Tests for the Reviews context.
  """

  use BiteBeacon.DataCase, async: true

  import BiteBeacon.Factory

  alias BiteBeacon.Facilities.{Facility, Facilities}
  alias BiteBeacon.Repo
  alias BiteBeacon.Reviews.{Review, Reviews}
  alias BiteBeacon.Users.{User, Users}
  alias BiteBeacon.Vendors.{Vendor, Vendors}

  describe "Review changeset functions" do
    setup do
      user = insert(:user)
      vendor = insert(:vendor)
      facility = insert(:facility, vendor_id: vendor.id)
    end

    test "valid review changeset passes" do
    end
  end
end
