defmodule BiteBeacon.UsersTest do
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
  end
end
