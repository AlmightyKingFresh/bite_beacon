defmodule BiteBeaconWeb.VendorConfirmationInstructionsLiveTest do
  use BiteBeaconWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import BiteBeacon.VendorFixtures

  alias BiteBeacon.Vendors
  alias BiteBeacon.Repo

  setup do
    %{vendor: vendor_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/vendors/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, vendor: vendor} do
      {:ok, lv, _html} = live(conn, ~p"/vendors/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", vendor: %{email: vendor.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Vendors.VendorToken, vendor_id: vendor.id).context == "confirm"
    end

    test "does not send confirmation token if vendor is confirmed", %{conn: conn, vendor: vendor} do
      Repo.update!(Vendors.Vendor.confirm_changeset(vendor))

      {:ok, lv, _html} = live(conn, ~p"/vendors/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", vendor: %{email: vendor.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Vendors.VendorToken, vendor_id: vendor.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/vendors/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", vendor: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Vendors.VendorToken) == []
    end
  end
end
