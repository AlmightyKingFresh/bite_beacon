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

  describe " Vendor CRUD" do
    setup do
      vendor1 = insert(:vendor)
      vendor2 = insert(:vendor)
      vendor3 = insert(:vendor)
      %{vendor1: vendor1, vendor2: vendor2, vendor3: vendor3}
    end

    test "list_vendors/0 returns all vendors", %{
      vendor1: vendor1,
      vendor2: vendor2,
      vendor3: vendor3
    } do
      vendors = Vendors.list_vendors()
      assert vendor1 in vendors
      assert vendor2 in vendors
      assert vendor3 in vendors
    end

    test "list vendors/0 returns nothing if table is empty" do
      Repo.delete_all(Vendor)
      vendors = Vendors.list_vendors()
      assert vendors == []
    end

    test "get_vendor/1 returns vendor with id", %{vendor3: vendor3} do
      fetched_vendor = Vendors.get_vendor(vendor3.id)
      assert fetched_vendor == vendor3
    end

    test "get_vendor/1 returns nothing when id isn't present in db" do
      fectched_vendor = Vendors.get_vendor(Ecto.UUID.generate())
      assert fectched_vendor == nil
    end

    test "get_vendor_by_email/1 returns vendor when email is in db", %{vendor2: vendor2} do
      fetched_vendor = Vendors.get_vendor_by_email(vendor2.email)
      assert fetched_vendor == vendor2
    end

    test "get_vendor_by_email/1 returns nothing if email doesn't exist in db" do
      fetched_vendor = Vendors.get_vendor_by_email(Internet.email())
      assert fetched_vendor == nil
    end

    test "register_vendor/1 inserts vendor into the db" do
      valid_attrs = %{
        first_name: Person.first_name(),
        last_name: Person.last_name(),
        email: Internet.email(),
        password: "Pa$$word",
        permit_id: valid_permit_id(),
        permit_status:
          Enum.random([
            "APPROVED",
            "EXPIRED",
            "REQUESTED",
            "SUSPEND",
            "ISSUED"
          ]),
        permit_approval_date: FakeTime.backward(Enum.random(10..500)),
        permit_application_received: FakeTime.backward(Enum.random(10..500)),
        prior_permit: Enum.random(0..5),
        permit_expiration_date: FakeTime.forward(Enum.random(10..500)),
        date_notice_of_intent_sent: FakeTime.backward(Enum.random(10..500))
      }

      {:ok, vendor} = Vendors.register_vendor(valid_attrs)

      assert Vendors.get_vendor_by_email(valid_attrs.email) ===
               Vendors.get_vendor_by_email(vendor.email)

      assert Vendors.get_vendor(vendor.id) === Vendors.get_vendor_by_email(valid_attrs.email)
    end

    test "register_vendor fails with bad data" do
      invalid_attrs = %{
        first_name: 33,
        last_name: "h",
        email: "33.org",
        password: 3344,
        permit_id: "hhhh1345*()",
        permit_status: "not sure",
        permit_approval_date: FakeTime.backward(Enum.random(10..500)),
        permit_application_received: FakeTime.backward(Enum.random(10..500)),
        prior_permit: Enum.random(0..5),
        permit_expiration_date: FakeTime.forward(Enum.random(10..500)),
        date_notice_of_intent_sent: FakeTime.backward(Enum.random(10..500))
      }

      {:error, changeset} = Vendors.register_vendor(invalid_attrs)

      assert errors_on(changeset) == %{
               password: ["is invalid"],
               email: ["must have the @ sign and no spaces"],
               permit_id: ["must be in the format ##MFF-#### (e.g. 21MFF-00073)"],
               first_name: ["is invalid"],
               last_name: ["should be at least 2 character(s)"],
               permit_status: ["is invalid"]
             }
    end

    test "change_vendor_email/2 works with valid email and existing vendor", %{vendor1: vendor1} do
      old_email = vendor1.email

      {:ok, updated_vendor} =
        Vendors.change_vendor_email(vendor1, %{email: "lientenantdan@goarmy.org"})

      updated_vendor.email

      assert old_email != updated_vendor.email
    end

    test "change_vendor_email/2 returns error when new email isn't valid", %{vendor1: vendor1} do
      {:error, changeset} = Vendors.change_vendor_email(vendor1, %{email: "kurtisblow.edu"})

      assert errors_on(changeset) == %{email: ["must have the @ sign and no spaces"]}
    end

    test "change_vendor_password/2 works with valid password and vendor", %{vendor2: vendor2} do
      old_hashed_password = vendor2.hashed_password

      {:ok, updated_vendor} =
        Vendors.change_vendor_password(vendor2, %{password: "!Q2w#E4r"})

      refute updated_vendor.hashed_password == old_hashed_password
    end

    test "change_vendor_password/2 errors with bad password", %{vendor3: vendor3} do
      {:error, changeset} = Vendors.change_vendor_password(vendor3, %{password: "badpassword"})

      assert errors_on(changeset) == %{
               password: [
                 "at least one digit or punctuation character",
                 "at least one upper case character"
               ]
             }
    end

    test "change_vendor_name/2 changes existing vendor's first name with valid data", %{
      vendor1: vendor1
    } do
      %Vendor{first_name: old_first_name} = vendor1

      {:ok, %Vendor{first_name: new_first_name}} =
        Vendors.change_vendor_name(vendor1, %{first_name: "First_Name"})

      assert old_first_name != new_first_name
      assert new_first_name == "First_Name"
    end

    test "change_vendor_name/2 changes existing vendor's last name with valid data", %{
      vendor1: vendor1
    } do
      %Vendor{last_name: old_last_name} = vendor1

      {:ok, %Vendor{last_name: new_last_name}} =
        Vendors.change_vendor_name(vendor1, %{last_name: "Last_Name"})

      assert old_last_name != new_last_name
      assert new_last_name == "Last_Name"
    end

    test "change_vendor_name/2 changes existing vendor's first and last names together with valid data",
         %{
           vendor1: vendor1
         } do
      %Vendor{first_name: old_first_name, last_name: old_last_name} = vendor1

      {:ok, %Vendor{first_name: new_first_name, last_name: new_last_name}} =
        Vendors.change_vendor_name(vendor1, %{first_name: "First_Name", last_name: "Last_Name"})

      assert old_first_name != new_first_name
      assert new_first_name == "First_Name"
      assert old_last_name != new_last_name
      assert new_last_name == "Last_Name"
    end

    test "change_vendor_name/2 errors if new first name is bad", %{vendor2: vendor2} do
      {:error, changeset} = Vendors.change_vendor_name(vendor2, %{first_name: "J"})

      assert errors_on(changeset) == %{first_name: ["should be at least 2 character(s)"]}
    end

    test "change_vendor_name/2 errors if new last name is bad", %{vendor2: vendor2} do
      {:error, changeset} = Vendors.change_vendor_name(vendor2, %{last_name: "J"})

      assert errors_on(changeset) == %{last_name: ["should be at least 2 character(s)"]}
    end

    test "change_vendor_name/2 errors if either new first or last name is bad", %{
      vendor2: vendor2
    } do
      {:error, changeset} =
        Vendors.change_vendor_name(vendor2, %{first_name: "J", last_name: "7"})

      assert errors_on(changeset) == %{
               first_name: ["should be at least 2 character(s)"],
               last_name: ["should be at least 2 character(s)"]
             }
    end
  end
end
