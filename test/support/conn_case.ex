defmodule BiteBeaconWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use BiteBeaconWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias BiteBeacon.Users.Users

  using do
    quote do
      # The default endpoint for testing
      @endpoint BiteBeaconWeb.Endpoint

      use BiteBeaconWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import BiteBeaconWeb.ConnCase
    end
  end

  setup tags do
    BiteBeacon.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = BiteBeacon.UsersFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = BiteBeacon.Users.Users.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  @doc """
  Setup helper that registers and logs in vendors.

      setup :register_and_log_in_vendor

  It stores an updated connection and a registered vendor in the
  test context.
  """
  def register_and_log_in_vendor(%{conn: conn}) do
    vendor = BiteBeacon.Vendor.Fixtures.vendor_fixture()
    %{conn: log_in_vendor(conn, vendor), vendor: vendor}
  end

  @doc """
  Logs the given `vendor` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_vendor(conn, vendor) do
    token = BiteBeacon.Vendors.Vendors.generate_vendor_session_token(vendor)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:vendor_token, token)
  end
end
