defmodule BiteBeacon.Factory do
  @moduledoc """
  test helpers for test fixtures using ExMachina.
  """

  use ExMachina.Ecto, repo: BiteBeacon.Repo

  alias BiteBeacon.Users.User
  alias BiteBeacon.Vendors.Vendor
  alias BiteBeacon.Facilities.Facility
  alias BiteBeacon.Reviews.Review
  alias Faker

  def user_factory do
    %User{
      email: Faker.Internet.email(),",
      password: "hello world!"
    }
  end

  def vendor_factory do
    %Vendor{
      name: "Vendor #{System.unique_integer()}",
      email: Faker.Internet.email(),
      password: "hello world!"
    }
  end

  def facility_factory do
    %Facility{
      name: "Facility #{System.unique_integer()}",
      address: "123 Main St",
      vendor_id: insert(:vendor).id
    }
  end

  def review_factory do
    %Review{
      body: "This is a review.",
      rating: Enum.random(1..5),
      user_id: insert(:user).id,
      facility_id: insert(:facility).id
    }
  end

  def review_with_no_body_factory do
    %Review{
      body: nil,
      rating: Enum.random(1..5),
      user_id: insert(:user).id,
      facility_id: insert(:facility).id
    }
  end
end
