defmodule BiteBeaconWeb.VendorAuthTest do
  use BiteBeaconWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias BiteBeacon.Vendors.Vendors
  alias BiteBeaconWeb.VendorAuth
  import BiteBeacon.VendorFixtures

  @remember_me_cookie "_bite_beacon_web_vendor_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, BiteBeaconWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{vendor: vendor_fixture(), conn: conn}
  end

  describe "log_in_vendor/3" do
    test "stores the vendor token in the session", %{conn: conn, vendor: vendor} do
      conn = VendorAuth.log_in_vendor(conn, vendor)
      assert token = get_session(conn, :vendor_token)
      assert get_session(conn, :live_socket_id) == "vendors_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Vendors.get_vendor_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, vendor: vendor} do
      conn = conn |> put_session(:to_be_removed, "value") |> VendorAuth.log_in_vendor(vendor)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, vendor: vendor} do
      conn = conn |> put_session(:vendor_return_to, "/hello") |> VendorAuth.log_in_vendor(vendor)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, vendor: vendor} do
      conn =
        conn |> fetch_cookies() |> VendorAuth.log_in_vendor(vendor, %{"remember_me" => "true"})

      assert get_session(conn, :vendor_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :vendor_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_vendor/1" do
    test "erases session and cookies", %{conn: conn, vendor: vendor} do
      vendor_token = Vendors.generate_vendor_session_token(vendor)

      conn =
        conn
        |> put_session(:vendor_token, vendor_token)
        |> put_req_cookie(@remember_me_cookie, vendor_token)
        |> fetch_cookies()
        |> VendorAuth.log_out_vendor()

      refute get_session(conn, :vendor_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Vendors.get_vendor_by_session_token(vendor_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "vendors_sessions:abcdef-token"
      BiteBeaconWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> VendorAuth.log_out_vendor()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if vendor is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> VendorAuth.log_out_vendor()
      refute get_session(conn, :vendor_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_vendor/2" do
    test "authenticates vendor from session", %{conn: conn, vendor: vendor} do
      vendor_token = Vendors.generate_vendor_session_token(vendor)

      conn =
        conn |> put_session(:vendor_token, vendor_token) |> VendorAuth.fetch_current_vendor([])

      assert conn.assigns.current_vendor.id == vendor.id
    end

    test "authenticates vendor from cookies", %{conn: conn, vendor: vendor} do
      logged_in_conn =
        conn |> fetch_cookies() |> VendorAuth.log_in_vendor(vendor, %{"remember_me" => "true"})

      vendor_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> VendorAuth.fetch_current_vendor([])

      assert conn.assigns.current_vendor.id == vendor.id
      assert get_session(conn, :vendor_token) == vendor_token

      assert get_session(conn, :live_socket_id) ==
               "vendors_sessions:#{Base.url_encode64(vendor_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, vendor: vendor} do
      _ = Vendors.generate_vendor_session_token(vendor)
      conn = VendorAuth.fetch_current_vendor(conn, [])
      refute get_session(conn, :vendor_token)
      refute conn.assigns.current_vendor
    end
  end

  describe "on_mount :mount_current_vendor" do
    test "assigns current_vendor based on a valid vendor_token", %{conn: conn, vendor: vendor} do
      vendor_token = Vendors.generate_vendor_session_token(vendor)
      session = conn |> put_session(:vendor_token, vendor_token) |> get_session()

      {:cont, updated_socket} =
        VendorAuth.on_mount(:mount_current_vendor, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_vendor.id == vendor.id
    end

    test "assigns nil to current_vendor assign if there isn't a valid vendor_token", %{conn: conn} do
      vendor_token = "invalid_token"
      session = conn |> put_session(:vendor_token, vendor_token) |> get_session()

      {:cont, updated_socket} =
        VendorAuth.on_mount(:mount_current_vendor, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_vendor == nil
    end

    test "assigns nil to current_vendor assign if there isn't a vendor_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        VendorAuth.on_mount(:mount_current_vendor, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_vendor == nil
    end
  end

  describe "on_mount :ensure_authenticated" do
    test "authenticates current_vendor based on a valid vendor_token", %{
      conn: conn,
      vendor: vendor
    } do
      vendor_token = Vendors.generate_vendor_session_token(vendor)
      session = conn |> put_session(:vendor_token, vendor_token) |> get_session()

      {:cont, updated_socket} =
        VendorAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_vendor.id == vendor.id
    end

    test "redirects to login page if there isn't a valid vendor_token", %{conn: conn} do
      vendor_token = "invalid_token"
      session = conn |> put_session(:vendor_token, vendor_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: BiteBeaconWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = VendorAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_vendor == nil
    end

    test "redirects to login page if there isn't a vendor_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: BiteBeaconWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = VendorAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_vendor == nil
    end
  end

  describe "on_mount :redirect_if_vendor_is_authenticated" do
    test "redirects if there is an authenticated  vendor ", %{conn: conn, vendor: vendor} do
      vendor_token = Vendors.generate_vendor_session_token(vendor)
      session = conn |> put_session(:vendor_token, vendor_token) |> get_session()

      assert {:halt, _updated_socket} =
               VendorAuth.on_mount(
                 :redirect_if_vendor_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "doesn't redirect if there is no authenticated vendor", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               VendorAuth.on_mount(
                 :redirect_if_vendor_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_vendor_is_authenticated/2" do
    test "redirects if vendor is authenticated", %{conn: conn, vendor: vendor} do
      conn =
        conn
        |> assign(:current_vendor, vendor)
        |> VendorAuth.redirect_if_vendor_is_authenticated([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if vendor is not authenticated", %{conn: conn} do
      conn = VendorAuth.redirect_if_vendor_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_vendor/2" do
    test "redirects if vendor is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> VendorAuth.require_authenticated_vendor([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/vendors/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> VendorAuth.require_authenticated_vendor([])

      assert halted_conn.halted
      assert get_session(halted_conn, :vendor_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> VendorAuth.require_authenticated_vendor([])

      assert halted_conn.halted
      assert get_session(halted_conn, :vendor_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> VendorAuth.require_authenticated_vendor([])

      assert halted_conn.halted
      refute get_session(halted_conn, :vendor_return_to)
    end

    test "does not redirect if vendor is authenticated", %{conn: conn, vendor: vendor} do
      conn =
        conn |> assign(:current_vendor, vendor) |> VendorAuth.require_authenticated_vendor([])

      refute conn.halted
      refute conn.status
    end
  end
end
