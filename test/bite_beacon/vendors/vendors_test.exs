defmodule BiteBeacon.VendorsTest do
  @moduledoc """
  Test suite for Vendors
  """
  use BiteBeacon.DataCase, async: true

  import BiteBeacon.Factory

  alias Faker.DateTime, as: FakeTime
  alias Faker.{Internet, Person}
  alias BiteBeacon.Repo
  alias BiteBeacon.Vendors.{Vendor, Vendors}

  @password "Pa$$word"
  @permit_id "21MFF-00073"

  describe "registration_changeset/2" do
    setup do
      vendor = build(:vendor)
      %{vendor: vendor}
    end

    test "valid registration changeset works" do
      changeset =
        Vendor.registration_changeset(%Vendor{}, %{
          first_name: Person.first_name(),
          last_name: Person.last_name(),
          email: Internet.email(),
          password: @password,
          permit_status: "APPROVED",
          permit_id: "21MFF-00073"
        })

      assert changeset.valid?
    end

    test "bad permit_id in changeset fails" do
      changeset =
        Vendor.registration_changeset(%Vendor{}, %{
          first_name: Person.first_name(),
          last_name: Person.last_name(),
          email: Internet.email(),
          password: @password,
          permit_status: "APPROVED",
          permit_id: "1234567"
        })

      assert %{permit_id: ["must be in the format ##MFF-#### (e.g. 21MFF-00073)"]} ==
               errors_on(changeset)

      refute changeset.valid?
    end

    test "bad email address in changeset fails" do
      changeset =
        Vendor.registration_changeset(%Vendor{}, %{
          first_name: Person.first_name(),
          last_name: Person.last_name(),
          email: "notanemailaddress.org",
          password: @password,
          permit_status: "APPROVED",
          permit_id: @permit_id
        })

      assert %{email: ["must have the @ sign and no spaces"]} == errors_on(changeset)
      refute changeset.valid?
    end

    test "bad permit status in changeset fails" do
      changeset =
        Vendor.registration_changeset(%Vendor{}, %{
          first_name: Person.first_name(),
          last_name: Person.last_name(),
          email: Internet.email(),
          password: @password,
          permit_status: "33",
          permit_id: @permit_id
        })

      assert %{permit_status: ["is invalid"]} == errors_on(changeset)
      refute changeset.valid?
    end

    test "bad first or last name in changeset fails" do
      changeset =
        Vendor.registration_changeset(%Vendor{}, %{
          first_name: "b",
          last_name: "4",
          email: Internet.email(),
          password: @password,
          permit_status: "APPROVED",
          permit_id: "21MFF-00073"
        })

      assert %{
               first_name: ["should be at least 2 character(s)"],
               last_name: ["should be at least 2 character(s)"]
             } == errors_on(changeset)

      refute changeset.valid?
    end

    test "bad password in changeset fails" do
      changeset =
        Vendor.registration_changeset(%Vendor{}, %{
          first_name: Person.first_name(),
          last_name: Person.last_name(),
          email: Internet.email(),
          password: "badpassword",
          permit_status: "APPROVED",
          permit_id: "21MFF-00073"
        })

      assert %{
               password: [
                 "at least one digit or punctuation character",
                 "at least one upper case character"
               ]
             } == errors_on(changeset)

      refute changeset.valid?
    end
  end

  describe "vendor update changeset functions" do
    test "email_changeset/3 works with valid data" do
      changeset = Vendor.email_changeset(%Vendor{}, %{email: Internet.email()})

      assert changeset.valid?
    end

    test "email_chanegeset/3 doesn't work with bad data" do
      changeset = Vendor.email_changeset(%Vendor{}, %{email: "Notatemail.edu"})

      assert %{email: ["must have the @ sign and no spaces"]} == errors_on(changeset)
      refute changeset.valid?
    end

    test "password_changeset/3 works with valid data" do
      changeset = Vendor.password_changeset(%Vendor{}, %{password: @password})

      assert changeset.valid?
    end

    test "password_changeset/3 doesn't work with bad data" do
      changeset = Vendor.password_changeset(%Vendor{}, %{password: "abcd123"})

      assert %{
               password: [
                 "at least one upper case character",
                 "should be at least 8 character(s)"
               ]
             } == errors_on(changeset)

      refute changeset.valid?
    end

    test "name_changeset/3 works with good first name data" do
      changeset = Vendor.name_changeset(%Vendor{}, %{first_name: "Denzel"})

      assert changeset.valid?
    end

    test "name_changeset/3 works with bad first name data" do
      changeset = Vendor.name_changeset(%Vendor{}, %{first_name: "K"})

      assert %{first_name: ["should be at least 2 character(s)"]} ==
               errors_on(changeset) |> IO.inspect()

      refute changeset.valid?
    end

    test "name_changeset/3 works with good last name data" do
      changeset = Vendor.name_changeset(%Vendor{}, %{last_name: "Washington"})

      assert changeset.valid?
    end

    test "name_changeset/3 breaks with bad last name data" do
      changeset = Vendor.name_changeset(%Vendor{}, %{last_name: "J"})

      assert %{last_name: ["should be at least 2 character(s)"]} ==
               errors_on(changeset)

      refute changeset.valid?
    end

    test "permit_id_changeset/2 works with valid permit id" do
      changeset = Vendor.permit_id_changeset(%Vendor{}, %{permit_id: @permit_id})

      assert changeset.valid?
    end

    test "permit_id_changeset/2 doesn't work with bad permit id" do
      changeset = Vendor.permit_id_changeset(%Vendor{}, %{permit_id: "52_pairs_of_socks"})

      assert %{permit_id: ["must be in the format ##MFF-#### (e.g. 21MFF-00073)"]} ==
               errors_on(changeset)

      refute changeset.valid?
    end

    test "permit status/2 works with valid permit status" do
      changeset = Vendor.permit_status_changeset(%Vendor{}, %{permit_status: "ISSUED"})

      assert changeset.valid?
    end

    test "permit status/2 errors with invalid permit status" do
      changeset = Vendor.permit_status_changeset(%Vendor{}, %{permit_status: "Um...."})

      assert %{permit_status: ["is invalid"]} == errors_on(changeset)
      refute changeset.valid?
    end

    test "permit_metadata_changeset/2 works with valid data" do
      changeset =
        Vendor.permit_metadata_changeset(%Vendor{}, %{
          permit_approval_date: FakeTime.backward(Enum.random(10..500)),
          permit_application_received: FakeTime.backward(Enum.random(10..500)),
          prior_permit: Enum.random(0..5),
          permit_expiration_date: FakeTime.forward(Enum.random(10..500))
        })

      assert changeset.valid?
    end

    test "permit_metadata_changeset/2 errors with invalid data" do
      changeset =
        Vendor.permit_metadata_changeset(%Vendor{}, %{
          permit_approval_date: 29,
          permit_application_received: "4:44",
          permit_expiration_date: {:tuple, :tuple},
          date_notice_of_intent_sent: "xmas"
        })

      assert %{
               permit_approval_date: ["is invalid"],
               permit_application_received: ["is invalid"],
               permit_expiration_date: ["is invalid"],
               date_notice_of_intent_sent: ["is invalid"]
             } = errors_on(changeset)

      refute changeset.valid?
    end
  end
end
