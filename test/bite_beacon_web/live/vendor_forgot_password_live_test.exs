defmodule BiteBeaconWeb.VendorForgotPasswordLiveTest do
  use BiteBeaconWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import BiteBeacon.VendorFixtures

  alias BiteBeacon.Vendors.Vendors
  alias BiteBeacon.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/vendors/reset_password")

      assert html =~ "Forgot your password?"
      assert has_element?(lv, ~s|a[href="#{~p"/vendors/register"}"]|, "Register")
      assert has_element?(lv, ~s|a[href="#{~p"/vendors/log_in"}"]|, "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_vendor(vendor_fixture())
        |> live(~p"/vendors/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{vendor: vendor_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, vendor: vendor} do
      {:ok, lv, _html} = live(conn, ~p"/vendors/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", vendor: %{"email" => vendor.email})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(Vendors.VendorToken, vendor_id: vendor.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/vendors/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", vendor: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(Vendors.VendorToken) == []
    end
  end
end
