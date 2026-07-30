defmodule BiteBeacon.VendorsTest do
  use BiteBeacon.DataCase

  import BiteBeacon.VendorFixtures
  alias BiteBeacon.Vendors.{Vendor, Vendors, VendorToken}

  describe "get_vendor_by_email/1" do
    test "does not return the vendor if the email does not exist" do
      refute Vendors.get_vendor_by_email("unknown@example.com")
    end

    test "returns the vendor if the email exists" do
      %{id: id} = vendor = vendor_fixture()
      assert %Vendor{id: ^id} = Vendors.get_vendor_by_email(vendor.email)
    end
  end

  describe "get_vendor_by_email_and_password/2" do
    test "does not return the vendor if the email does not exist" do
      refute Vendors.get_vendor_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the vendor if the password is not valid" do
      vendor = vendor_fixture()
      refute Vendors.get_vendor_by_email_and_password(vendor.email, "invalid")
    end

    test "returns the vendor if the email and password are valid" do
      %{id: id} = vendor = vendor_fixture()

      assert %Vendor{id: ^id} =
               Vendors.get_vendor_by_email_and_password(vendor.email, valid_vendor_password())
    end
  end

  describe "get_vendor!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Vendors.get_vendor!(-1)
      end
    end

    test "returns the vendor with the given id" do
      %{id: id} = vendor = vendor_fixture()
      assert %Vendor{id: ^id} = Vendors.get_vendor!(vendor.id)
    end
  end

  describe "register_vendor/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Vendors.register_vendor(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Vendors.register_vendor(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Vendors.register_vendor(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = vendor_fixture()
      {:error, changeset} = Vendors.register_vendor(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Vendors.register_vendor(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers vendors with a hashed password" do
      email = unique_vendor_email()
      {:ok, vendor} = Vendors.register_vendor(valid_vendor_attributes(email: email))
      assert vendor.email == email
      assert is_binary(vendor.hashed_password)
      assert is_nil(vendor.confirmed_at)
      assert is_nil(vendor.password)
    end
  end

  describe "change_vendor_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Vendors.change_vendor_registration(%Vendor{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_vendor_email()
      password = valid_vendor_password()

      changeset =
        Vendors.change_vendor_registration(
          %Vendor{},
          valid_vendor_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_vendor_email/2" do
    test "returns a vendor changeset" do
      assert %Ecto.Changeset{} = changeset = Vendors.change_vendor_email(%Vendor{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_vendor_email/3" do
    setup do
      %{vendor: vendor_fixture()}
    end

    test "requires email to change", %{vendor: vendor} do
      {:error, changeset} = Vendors.apply_vendor_email(vendor, valid_vendor_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{vendor: vendor} do
      {:error, changeset} =
        Vendors.apply_vendor_email(vendor, valid_vendor_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{vendor: vendor} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Vendors.apply_vendor_email(vendor, valid_vendor_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{vendor: vendor} do
      %{email: email} = vendor_fixture()
      password = valid_vendor_password()

      {:error, changeset} = Vendors.apply_vendor_email(vendor, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{vendor: vendor} do
      {:error, changeset} =
        Vendors.apply_vendor_email(vendor, "invalid", %{email: unique_vendor_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{vendor: vendor} do
      email = unique_vendor_email()

      {:ok, vendor} =
        Vendors.apply_vendor_email(vendor, valid_vendor_password(), %{email: email})

      assert vendor.email == email
      assert Vendors.get_vendor!(vendor.id).email != email
    end
  end

  describe "deliver_vendor_update_email_instructions/3" do
    setup do
      %{vendor: vendor_fixture()}
    end

    test "sends token through notification", %{vendor: vendor} do
      token =
        extract_vendor_token(fn url ->
          Vendors.deliver_vendor_update_email_instructions(vendor, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert vendor_token = Repo.get_by(VendorToken, token: :crypto.hash(:sha256, token))
      assert vendor_token.vendor_id == vendor.id
      assert vendor_token.sent_to == vendor.email
      assert vendor_token.context == "change:current@example.com"
    end
  end

  describe "update_vendor_email/2" do
    setup do
      vendor = vendor_fixture()
      email = unique_vendor_email()

      token =
        extract_vendor_token(fn url ->
          Vendors.deliver_vendor_update_email_instructions(
            %{vendor | email: email},
            vendor.email,
            url
          )
        end)

      %{vendor: vendor, token: token, email: email}
    end

    test "updates the email with a valid token", %{vendor: vendor, token: token, email: email} do
      assert Vendors.update_vendor_email(vendor, token) == :ok
      changed_vendor = Repo.get!(Vendor, vendor.id)
      assert changed_vendor.email != vendor.email
      assert changed_vendor.email == email
      assert changed_vendor.confirmed_at
      assert changed_vendor.confirmed_at != vendor.confirmed_at
      refute Repo.get_by(VendorToken, vendor_id: vendor.id)
    end

    test "does not update email with invalid token", %{vendor: vendor} do
      assert Vendors.update_vendor_email(vendor, "oops") == :error
      assert Repo.get!(Vendor, vendor.id).email == vendor.email
      assert Repo.get_by(VendorToken, vendor_id: vendor.id)
    end

    test "does not update email if vendor email changed", %{vendor: vendor, token: token} do
      assert Vendors.update_vendor_email(%{vendor | email: "current@example.com"}, token) ==
               :error

      assert Repo.get!(Vendor, vendor.id).email == vendor.email
      assert Repo.get_by(VendorToken, vendor_id: vendor.id)
    end

    test "does not update email if token expired", %{vendor: vendor, token: token} do
      {1, nil} = Repo.update_all(VendorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Vendors.update_vendor_email(vendor, token) == :error
      assert Repo.get!(Vendor, vendor.id).email == vendor.email
      assert Repo.get_by(VendorToken, vendor_id: vendor.id)
    end
  end

  describe "change_vendor_password/2" do
    test "returns a vendor changeset" do
      assert %Ecto.Changeset{} = changeset = Vendors.change_vendor_password(%Vendor{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Vendors.change_vendor_password(%Vendor{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_vendor_password/3" do
    setup do
      %{vendor: vendor_fixture()}
    end

    test "validates password", %{vendor: vendor} do
      {:error, changeset} =
        Vendors.update_vendor_password(vendor, valid_vendor_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{vendor: vendor} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Vendors.update_vendor_password(vendor, valid_vendor_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{vendor: vendor} do
      {:error, changeset} =
        Vendors.update_vendor_password(vendor, "invalid", %{password: valid_vendor_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{vendor: vendor} do
      {:ok, vendor} =
        Vendors.update_vendor_password(vendor, valid_vendor_password(), %{
          password: "new valid password"
        })

      assert is_nil(vendor.password)
      assert Vendors.get_vendor_by_email_and_password(vendor.email, "new valid password")
    end

    test "deletes all tokens for the given vendor", %{vendor: vendor} do
      _ = Vendors.generate_vendor_session_token(vendor)

      {:ok, _} =
        Vendors.update_vendor_password(vendor, valid_vendor_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(VendorToken, vendor_id: vendor.id)
    end
  end

  describe "generate_vendor_session_token/1" do
    setup do
      %{vendor: vendor_fixture()}
    end

    test "generates a token", %{vendor: vendor} do
      token = Vendors.generate_vendor_session_token(vendor)
      assert vendor_token = Repo.get_by(VendorToken, token: token)
      assert vendor_token.context == "session"

      # Creating the same token for another vendor should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%VendorToken{
          token: vendor_token.token,
          vendor_id: vendor_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_vendor_by_session_token/1" do
    setup do
      vendor = vendor_fixture()
      token = Vendors.generate_vendor_session_token(vendor)
      %{vendor: vendor, token: token}
    end

    test "returns vendor by token", %{vendor: vendor, token: token} do
      assert session_vendor = Vendors.get_vendor_by_session_token(token)
      assert session_vendor.id == vendor.id
    end

    test "does not return vendor for invalid token" do
      refute Vendors.get_vendor_by_session_token("oops")
    end

    test "does not return vendor for expired token", %{token: token} do
      {1, nil} = Repo.update_all(VendorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Vendors.get_vendor_by_session_token(token)
    end
  end

  describe "delete_vendor_session_token/1" do
    test "deletes the token" do
      vendor = vendor_fixture()
      token = Vendors.generate_vendor_session_token(vendor)
      assert Vendors.delete_vendor_session_token(token) == :ok
      refute Vendors.get_vendor_by_session_token(token)
    end
  end

  describe "deliver_vendor_confirmation_instructions/2" do
    setup do
      %{vendor: vendor_fixture()}
    end

    test "sends token through notification", %{vendor: vendor} do
      token =
        extract_vendor_token(fn url ->
          Vendors.deliver_vendor_confirmation_instructions(vendor, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert vendor_token = Repo.get_by(VendorToken, token: :crypto.hash(:sha256, token))
      assert vendor_token.vendor_id == vendor.id
      assert vendor_token.sent_to == vendor.email
      assert vendor_token.context == "confirm"
    end
  end

  describe "confirm_vendor/1" do
    setup do
      vendor = vendor_fixture()

      token =
        extract_vendor_token(fn url ->
          Vendors.deliver_vendor_confirmation_instructions(vendor, url)
        end)

      %{vendor: vendor, token: token}
    end

    test "confirms the email with a valid token", %{vendor: vendor, token: token} do
      assert {:ok, confirmed_vendor} = Vendors.confirm_vendor(token)
      assert confirmed_vendor.confirmed_at
      assert confirmed_vendor.confirmed_at != vendor.confirmed_at
      assert Repo.get!(Vendor, vendor.id).confirmed_at
      refute Repo.get_by(VendorToken, vendor_id: vendor.id)
    end

    test "does not confirm with invalid token", %{vendor: vendor} do
      assert Vendors.confirm_vendor("oops") == :error
      refute Repo.get!(Vendor, vendor.id).confirmed_at
      assert Repo.get_by(VendorToken, vendor_id: vendor.id)
    end

    test "does not confirm email if token expired", %{vendor: vendor, token: token} do
      {1, nil} = Repo.update_all(VendorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Vendors.confirm_vendor(token) == :error
      refute Repo.get!(Vendor, vendor.id).confirmed_at
      assert Repo.get_by(VendorToken, vendor_id: vendor.id)
    end
  end

  describe "deliver_vendor_reset_password_instructions/2" do
    setup do
      %{vendor: vendor_fixture()}
    end

    test "sends token through notification", %{vendor: vendor} do
      token =
        extract_vendor_token(fn url ->
          Vendors.deliver_vendor_reset_password_instructions(vendor, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert vendor_token = Repo.get_by(VendorToken, token: :crypto.hash(:sha256, token))
      assert vendor_token.vendor_id == vendor.id
      assert vendor_token.sent_to == vendor.email
      assert vendor_token.context == "reset_password"
    end
  end

  describe "get_vendor_by_reset_password_token/1" do
    setup do
      vendor = vendor_fixture()

      token =
        extract_vendor_token(fn url ->
          Vendors.deliver_vendor_reset_password_instructions(vendor, url)
        end)

      %{vendor: vendor, token: token}
    end

    test "returns the vendor with valid token", %{vendor: %{id: id}, token: token} do
      assert %Vendor{id: ^id} = Vendors.get_vendor_by_reset_password_token(token)
      assert Repo.get_by(VendorToken, vendor_id: id)
    end

    test "does not return the vendor with invalid token", %{vendor: vendor} do
      refute Vendors.get_vendor_by_reset_password_token("oops")
      assert Repo.get_by(VendorToken, vendor_id: vendor.id)
    end

    test "does not return the vendor if token expired", %{vendor: vendor, token: token} do
      {1, nil} = Repo.update_all(VendorToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Vendors.get_vendor_by_reset_password_token(token)
      assert Repo.get_by(VendorToken, vendor_id: vendor.id)
    end
  end

  describe "reset_vendor_password/2" do
    setup do
      %{vendor: vendor_fixture()}
    end

    test "validates password", %{vendor: vendor} do
      {:error, changeset} =
        Vendors.reset_vendor_password(vendor, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{vendor: vendor} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Vendors.reset_vendor_password(vendor, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{vendor: vendor} do
      {:ok, updated_vendor} =
        Vendors.reset_vendor_password(vendor, %{password: "new valid password"})

      assert is_nil(updated_vendor.password)
      assert Vendors.get_vendor_by_email_and_password(vendor.email, "new valid password")
    end

    test "deletes all tokens for the given vendor", %{vendor: vendor} do
      _ = Vendors.generate_vendor_session_token(vendor)
      {:ok, _} = Vendors.reset_vendor_password(vendor, %{password: "new valid password"})
      refute Repo.get_by(VendorToken, vendor_id: vendor.id)
    end
  end

  describe "inspect/2 for the Vendor module" do
    test "does not include password" do
      refute inspect(%Vendor{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
