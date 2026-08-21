defmodule BiteBeacon.UsersTest do
  @moduledoc """
  Test suite for Users context.
  """
  use BiteBeacon.DataCase, async: true

  import BiteBeacon.Factory

  alias Faker.Internet
  alias BiteBeacon.Repo
  alias BiteBeacon.Users.{User, Users}

  @password "Pa$$word"

  describe "registration_changeset/2" do
    setup do
      user = build(:user)
      %{user: user}
    end

    test "valid registration changeset works" do
      changeset =
        User.registration_changeset(%User{}, %{
          name: Internet.user_name(),
          email: Internet.email(),
          password: @password
        })

      assert changeset.valid?
    end

    test "too few characters in name registration changeset fails" do
      changeset =
        User.registration_changeset(%User{}, %{
          name: "ai",
          email: Internet.email(),
          password: @password
        })

      assert %{name: ["must be between 4 and 30 characters"]} = errors_on(changeset)
      refute changeset.valid?
    end

    test "too many characters in name registration changeset fails" do
      changeset =
        User.registration_changeset(%User{}, %{
          name: "thisisaveryveryveryverylongname",
          email: Internet.email(),
          password: @password
        })

      assert %{name: ["must be between 4 and 30 characters"]} = errors_on(changeset)
      refute changeset.valid?
    end

    test "malformed email registration changeset fails" do
      changeset =
        User.registration_changeset(%User{}, %{
          name: Internet.user_name(),
          email: "invalidemail.org",
          password: @password
        })

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
      refute changeset.valid?
    end

    test "too many characters in email registration changeset fails" do
      changeset =
        User.registration_changeset(%User{}, %{
          name: Internet.user_name(),
          email: "someridiculouslylongemailaddress@domain.com",
          password: @password
        })

      assert %{email: ["must be at most 35 characters"]} = errors_on(changeset)
      refute changeset.valid?
    end

    test "too few characters in password registration changeset fails" do
      changeset =
        User.registration_changeset(%User{}, %{
          name: Internet.user_name(),
          email: Internet.email(),
          password: "123"
        })

      assert password:
               {"must be between 6 and 35 characters",
                [count: 6, validation: :length, kind: :min, type: :string]} in changeset.errors

      refute changeset.valid?
    end

    test "too many characters in password registration changeset fails" do
      changeset =
        User.registration_changeset(%User{}, %{
          name: Internet.user_name(),
          email: Internet.email(),
          password: "thisisaverylongpasswordthatexceedsthemaximumlength"
        })

      assert password:
               {"must be between 6 and 35 characters",
                [count: 6, validation: :length, kind: :min, type: :string]} in changeset.errors

      refute changeset.valid?
    end

    test "password missing lowercase character registration changeset fails" do
      changeset =
        User.registration_changeset(%User{}, %{
          name: Internet.user_name(),
          email: Internet.email(),
          password: "PASSWORD1!"
        })

      refute changeset.valid?
      assert %{password: ["at least one lower case character"]} = errors_on(changeset)
    end

    test "password missing uppercase character registration changeset fails" do
      changeset =
        User.registration_changeset(%User{}, %{
          name: Internet.user_name(),
          email: Internet.email(),
          password: "password1!"
        })

      refute changeset.valid?
      assert %{password: ["at least one upper case character"]} = errors_on(changeset)
    end

    test "password missing digit or punctuation character registration changeset fails" do
      changeset =
        User.registration_changeset(%User{}, %{
          name: Internet.user_name(),
          email: Internet.email(),
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
          email: Internet.email(),
          name: Internet.user_name(),
          password: "Pa$$word123!"
        })

      assert changeset.valid?
      assert get_change(changeset, :hashed_password)
      # cleared after hashing
      refute get_change(changeset, :password)
    end
  end

  describe "user update changeset functions" do
    test "valid name given to name_changeset/3 works" do
      changeset =
        User.name_changeset(%User{}, %{
          name: "NewName"
        })

      assert changeset.valid?
      assert get_change(changeset, :name) == "NewName"
    end

    test "invalid name given to name_changeset/3 fails" do
      changeset =
        User.name_changeset(%User{}, %{
          name: "a"
        })

      refute changeset.valid?
      assert %{name: ["must be between 4 and 30 characters"]} = errors_on(changeset)
    end

    test "valid email given to email_changeset/3 given to  works" do
      changeset =
        User.email_changeset(%User{}, %{
          email: "cornholio@example.com"
        })

      assert changeset.valid?
      assert get_change(changeset, :email) == "cornholio@example.com"
    end

    test "invalid email given to email_changeset/3 fails" do
      changeset =
        User.email_changeset(%User{}, %{
          email: "invalidemail.edu"
        })

      refute changeset.valid?
      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "valid password given to password_changeset/3 works" do
      changeset =
        User.password_changeset(%User{}, %{
          password: "NewPa$$word123!"
        })

      assert changeset.valid?
      assert get_change(changeset, :hashed_password)
      refute get_change(changeset, :password)
    end

    test "invalid password given to password_changeset fails" do
      changeset =
        User.password_changeset(%User{}, %{
          password: "short"
        })

      refute changeset.valid?

      assert password:
               {"must be between 6 and 35 characters",
                [count: 6, validation: :length, kind: :min, type: :string]} in changeset.errors
    end
  end

  describe " User CRUD operations" do
    setup do
      user1 = insert(:user)
      user2 = insert(:user)
      user3 = insert(:user)
      %{user1: user1, user2: user2, user3: user3}
    end

    test "list_users/0 returns all users", %{user1: user1, user2: user2, user3: user3} do
      users = Users.list_users()
      assert length(users) == 3
      assert user1 in users
      assert user2 in users
      assert user3 in users
    end

    test "list_users/0 returns nothing table is empty" do
      Repo.delete_all(User)
      users = Users.list_users()
      assert users == []
    end

    test "get_user/1 returns the user with given id", %{user2: user2} do
      %User{id: id, email: email} = Users.get_user(user2.id)

      assert user2.id == id
      assert user2.email == email
    end

    test "get_user/1 returns nothing when no user with given id exists" do
      user = Users.get_user(Ecto.UUID.generate())

      assert user == nil
    end

    test "get_user_by_email/1 returns the user with given email", %{user1: user1} do
      %User{email: email, id: id} = Users.get_user_by_email(user1.email)

      assert user1.email == email
      assert user1.id == id
    end

    test "get_user_by_name/1 returns the user with given name", %{user3: user3} do
      %User{name: name, id: id} = Users.get_user_by_name(user3.name)

      assert user3.name == name
      assert user3.id == id
    end

    test "register_user/1 creates a user with valid data" do
      valid_attrs = %{
        name: "Valid User",
        email: "validuser@example.com",
        password: "Pa$$word"
      }

      {:ok, user} = Users.register_user(valid_attrs)
      assert user.name == "Valid User"
      assert user.email == "validuser@example.com"
      assert user.hashed_password != nil
    end

    test "register_user/1 fails if email already exists", %{user3: user3} do
      invalid_attrs = %{
        name: "Ichigo Kurosaki",
        email: user3.email,
        password: "Pa$$word"
      }

      {:error, changeset} = Users.register_user(invalid_attrs)
      assert %{email: ["has already been taken"]} == errors_on(changeset)
      refute changeset.valid?
    end

    test "register_user/1 returns error changeset with invalid data" do
      invalid_attrs = %{
        name: "a",
        email: "invalidemail",
        password: "short"
      }

      {:error, changeset} = Users.register_user(invalid_attrs)
      refute changeset.valid?
      assert %{name: ["must be between 4 and 30 characters"]} = errors_on(changeset)
      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)

      assert password:
               {"must be between 6 and 35 characters",
                [count: 6, validation: :length, kind: :min, type: :string]} in changeset.errors
    end

    test "update_user_name/2 changes the user's name with valid name change data", %{user1: user1} do
      valid_attrs = %{name: "Naruto Uzumaki"}
      {:ok, updated_user} = Users.update_user_name(user1, valid_attrs)
      assert updated_user.name == "Naruto Uzumaki"
    end

    test "update_user_name/2 returns error changeset with invalid name change data", %{
      user2: user2
    } do
      invalid_attrs = %{name: "a"}
      {:error, changeset} = Users.update_user_name(user2, invalid_attrs)
      refute changeset.valid?
      assert %{name: ["must be between 4 and 30 characters"]} = errors_on(changeset)
    end

    test "update_user_email/2 changes the user's email with valid email change data", %{
      user2: user2
    } do
      valid_attrs = %{email: "newemail@example.com"}
      {:ok, updated_user} = Users.update_user_email(user2, valid_attrs)
      assert updated_user.email == "newemail@example.com"
    end

    test "update_user_email/2 returns error changeset with invalid email change data", %{
      user1: user1
    } do
      invalid_attrs = %{email: "gwent.org"}
      {:error, changeset} = Users.update_user_email(user1, invalid_attrs)
      refute changeset.valid?
      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "update_user_password/2 changes the user's password with valid password change data", %{
      user2: user2
    } do
      old_hashed_password = user2.hashed_password
      valid_attrs = %{password: "c0rNy!!!"}
      {:ok, updated_user} = Users.update_user_password(user2, valid_attrs)

      refute updated_user.hashed_password == old_hashed_password
    end

    test "update_user_password/2 returns error changeset with invalid password change data", %{
      user1: user1
    } do
      invalid_attrs = %{password: "27"}
      {:error, changeset} = Users.update_user_password(user1, invalid_attrs)

      refute changeset.valid?

      assert %{
               password: [
                 "at least one upper case character",
                 "at least one lower case character",
                 "must be between 6 and 35 characters"
               ]
             } == errors_on(changeset)
    end
  end
end
