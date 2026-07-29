defmodule BiteBeaconWeb.VendorSessionControllerTest do
  use BiteBeaconWeb.ConnCase, async: true

  import BiteBeacon.AccountsFixtures

  setup do
    %{vendor: vendor_fixture()}
  end

  describe "POST /vendors/log_in" do
    test "logs the vendor in", %{conn: conn, vendor: vendor} do
      conn =
        post(conn, ~p"/vendors/log_in", %{
          "vendor" => %{"email" => vendor.email, "password" => valid_vendor_password()}
        })

      assert get_session(conn, :vendor_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ vendor.email
      assert response =~ ~p"/vendors/settings"
      assert response =~ ~p"/vendors/log_out"
    end

    test "logs the vendor in with remember me", %{conn: conn, vendor: vendor} do
      conn =
        post(conn, ~p"/vendors/log_in", %{
          "vendor" => %{
            "email" => vendor.email,
            "password" => valid_vendor_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_bite_beacon_web_vendor_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the vendor in with return to", %{conn: conn, vendor: vendor} do
      conn =
        conn
        |> init_test_session(vendor_return_to: "/foo/bar")
        |> post(~p"/vendors/log_in", %{
          "vendor" => %{
            "email" => vendor.email,
            "password" => valid_vendor_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, vendor: vendor} do
      conn =
        conn
        |> post(~p"/vendors/log_in", %{
          "_action" => "registered",
          "vendor" => %{
            "email" => vendor.email,
            "password" => valid_vendor_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, vendor: vendor} do
      conn =
        conn
        |> post(~p"/vendors/log_in", %{
          "_action" => "password_updated",
          "vendor" => %{
            "email" => vendor.email,
            "password" => valid_vendor_password()
          }
        })

      assert redirected_to(conn) == ~p"/vendors/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/vendors/log_in", %{
          "vendor" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/vendors/log_in"
    end
  end

  describe "DELETE /vendors/log_out" do
    test "logs the vendor out", %{conn: conn, vendor: vendor} do
      conn = conn |> log_in_vendor(vendor) |> delete(~p"/vendors/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :vendor_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the vendor is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/vendors/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :vendor_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
