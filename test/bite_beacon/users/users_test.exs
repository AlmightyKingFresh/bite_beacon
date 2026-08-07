defmodule BiteBeacon.UsersTest do
  @moduledoc """
  Test suite for BiteBeacon.Users context.
  """
  use BiteBeacon.DataCase, async: true

  import BiteBeacon.Factory

  alias BiteBeacon.Users.{User, Users, UserToken}
  alias BiteBeacon.Repo

  describe "registration changeset/2" do
    setup do
      user = build(:user)
      %{user: user}
    end

    test "valid registration changeset works", %{user: user} do
      changeset =
        User.registration_changeset(%User{}, %{
          name: user.name,
          email: user.email,
          password: user.password
        })

      assert changeset.valid?
    end

    test "too few characters in name registartion changeset fails", %{user: user} do
      changeset =
        User.registration_changeset(%User{}, %{
          name: "ai",
          email: user.email,
          password: user.password
        })

      assert %{name: ["must be between 4 and 30 characters"]} = errors_on(changeset)
      refute changeset.valid?
    end

    test "too many characters in name registration changeset fails", %{user: user} do
      changeset =
        User.registration_changeset(%User{}, %{
          name: "thisisaveryveryveryverylongname",
          email: user.email,
          password: user.password
        })

      assert %{name: ["must be between 4 and 30 characters"]} = errors_on(changeset)
      refute changeset.valid?
    end

    test "malformed email registration changeset fails", %{user: user} do
      changeset =
        User.registration_changeset(%User{}, %{
          name: user.name,
          email: "invalidemail.org",
          password: user.password
        })

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
      refute changeset.valid?
    end

    test "too many characters in email registration changeset fails", %{user: user} do
      changeset =
        User.registration_changeset(%User{}, %{
          name: user.name,
          email: "someridiculouslylongemailaddress@domain.com",
          password: user.password
        })

      assert %{email: ["must be at most 35 characters"]} = errors_on(changeset)
      refute changeset.valid?
    end

    test "too few characters in password registration changeset fails", %{user: user} do
      changeset =
        User.registration_changeset(%User{}, %{
          name: user.name,
          email: user.email,
          password: "123"
        })

      assert password:
               {"must be between 6 and 35 characters",
                [count: 6, validation: :length, kind: :min, type: :string]} in changeset.errors

      refute changeset.valid?
    end

    test "too many characters in password registration changeset fails", %{user: user} do
      changeset =
        User.registration_changeset(%User{}, %{
          name: user.name,
          email: user.email,
          password: "thisisaverylongpasswordthatexceedsthemaximumlength"
        })

      assert password:
               {"must be between 6 and 35 characters",
                [count: 6, validation: :length, kind: :min, type: :string]} in changeset.errors

      refute changeset.valid?
    end

    test "password missing lowercase character registration changeset fails", %{user: user} do
      changeset =
        User.registration_changeset(%User{}, %{
          name: user.name,
          email: user.email,
          password: "PASSWORD1!"
        })

      refute changeset.valid?
      assert %{password: ["at least one lower case character"]} = errors_on(changeset)
    end

    test "password missing uppercase character registration changeset fails", %{user: user} do
      changeset =
        User.registration_changeset(%User{}, %{
          name: user.name,
          email: user.email,
          password: "password1!"
        })

      refute changeset.valid?
      assert %{password: ["at least one upper case character"]} = errors_on(changeset)
    end

    test "password missing digit or punctuation character registration changeset fails", %{
      user: user
    } do
      changeset =
        User.registration_changeset(%User{}, %{
          name: user.name,
          email: user.email,
          password: "Password"
        })

      refute changeset.valid?

      assert %{
               password: [
                 " must have a capital letter, a lowercase letter, and adigit or punctuation character"
               ]
             } = errors_on(changeset)
    end

    test "hashes the password" do
      changeset =
        User.registration_changeset(%User{}, %{
          email: "test@example.com",
          name: "testuser",
          password: "Pa$$word123!"
        })

      assert changeset.valid?
      assert get_change(changeset, :hashed_password)
      # cleared after hashing
      refute get_change(changeset, :password)
    end
  end

  describe "user update changesets" do
    setup do
      user = insert(:user)
      %{user: user}
    end

    test "valid name update changeset works", %{user: user} do
      changeset =
        User.name_changeset(user, %{
          name: "NewName",
          email: user.email
        })

      assert changeset.valid?
      assert get_change(changeset, :name) == "NewName"
    end

    test "invalid name update changeset fails", %{user: user} do
      changeset =
        User.name_changeset(user, %{
          name: "a",
          email: user.email
        })

      refute changeset.valid?
      assert %{name: ["must be between 4 and 30 characters"]} = errors_on(changeset)
    end

    test "valid email update changeset works", %{user: user} do
      changeset =
        User.email_changeset(user, %{
          name: user.name,
          email: "cornholio@example.com"
        })

      assert changeset.valid?
      assert get_change(changeset, :email) == "cornholio@example.com"
    end

    test "invalid email update changeset fails", %{user: user} do
      changeset =
        User.email_changeset(user, %{
          name: user.name,
          email: "invalidemail.edu"
        })

      refute changeset.valid?
      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "valid password update changeset works", %{user: user} do
      changeset =
        User.password_changeset(user, %{
          name: user.name,
          email: user.email,
          password: "NewPa$$word123!"
        })

      assert changeset.valid?
      assert get_change(changeset, :hashed_password)
      refute get_change(changeset, :password)
    end

    test "invalid password update changeset fails", %{user: user} do
      changeset =
        User.password_changeset(user, %{
          name: user.name,
          email: user.email,
          password: "short"
        })

      refute changeset.valid?

      assert password:
               {"must be between 6 and 35 characters",
                [count: 6, validation: :length, kind: :min, type: :string]} in changeset.errors
    end
  end
end
