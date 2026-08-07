defmodule BiteBeacon.Factory do
  @moduledoc """
  test helpers for test fixtures using ExMachina.
  """

  use ExMachina.Ecto, repo: BiteBeacon.Repo

  alias BiteBeacon.Facilities.Facility
  alias BiteBeacon.Reviews.Review
  alias BiteBeacon.Users.User
  alias BiteBeacon.Vendors.Vendor
  alias Faker.DateTime, as: FakeTime
  alias Faker.{Address, Cannabis, Person, Internet, Lorem, Gov}

  def user_factory do
    %User{
      email: Internet.email(),
      password: "Pa$$word",
      name: "DenzelistheGoat836",
      confirmed_at: DateTime.utc_now(),
      hashed_password: Bcrypt.hash_pwd_salt("Pa$$word")
    }
  end

  def vendor_factory do
    %Vendor{
      first_name: Person.first_name(),
      last_name: Person.last_name(),
      email: Internet.email(),
      password: "Pa$$word",
      permit_id: Gov.Us.ein(),
      permit_status:
        Enum.random([
          "APPROVED",
          "EXPIRED",
          "REQUESTED",
          "SUSPEND",
          "ISSUED"
        ]),
      permit_approval_date: FakeTime.backward(Enum.random(1..500)),
      permit_application_received: FakeTime.backward(Enum.random(1..500)),
      prior_permit: Enum.random(0..5),
      permit_expiration_date: FakeTime.forward(Enum.random(1..500)),
      date_notice_of_intent_sent: FakeTime.backward(Enum.random(1..500))
    }
  end

  def facility_factory do
    block = "#{Enum.random(1000..9999)}#{Enum.random(?A..?Z) |> List.wrap() |> List.to_string()}"
    lot = String.pad_leading("#{Enum.random(1..999)}", 3, "0")

    shedules = [
      "Mon-Fri 10am-6pm",
      "Thurs-Sun 10am-11pm",
      "Mon-Fri 11am-7pm",
      "Mon-Sun 11am-7pm",
      "Tues-Sat. 1pm-1am",
      "Mon-Sun 1pm-1am",
      "Mon-Fri 9am-5pm",
      "Mon-Sun 9am-11pm",
      "Wed-Fri 8am-4pm",
      "Mon-Sun 8am-4pm"
    ]

    latitude = Address.latitude()
    longitude = Address.longitude()

    %Facility{
      name: Cannabis.brand(),
      address: Address.street_address(),
      vendor_id: insert(:vendor).id,
      type: Enum.random(["Truck", "Push Cart"]),
      cnn: Enum.random(1..2_000_000),
      location_description: Address.street_name() <> " to " <> Address.street_name(),
      block: block,
      lot: lot,
      block_lot: block <> lot,
      cuisine:
        Faker.Food.dish() <>
          ", " <> Faker.Food.dish() <> ", " <> Faker.Food.dish() <> ", " <> Faker.Food.dish(),
      x: Float.round(:rand.uniform() * 10_000_000, 3),
      y: Float.round(:rand.uniform() * 10_000_000, 3),
      latitude: latitude,
      longitude: longitude,
      schedule_url: Internet.url(),
      schedule: Enum.random(shedules),
      location: "(#{latitude}, #{longitude})",
      fire_prevention_districts: Enum.random(1..20),
      police_districts: Enum.random(1..10),
      supervisor_districts: Enum.random(1..11),
      zip_codes: Enum.random(1..65),
      neighborhoods: Enum.random(1..93)
    }
  end

  def review_factory do
    %Review{
      body: Lorem.paragraph(),
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
