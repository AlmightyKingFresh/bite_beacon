defmodule BiteBeaconWeb.VendorSettingsLiveTest do
  use BiteBeaconWeb.ConnCase, async: true

  alias BiteBeacon.Accounts
  import Phoenix.LiveViewTest
  import BiteBeacon.AccountsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_vendor(vendor_fixture())
        |> live(~p"/vendors/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if vendor is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/vendors/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/vendors/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_vendor_password()
      vendor = vendor_fixture(%{password: password})
      %{conn: log_in_vendor(conn, vendor), vendor: vendor, password: password}
    end

    test "updates the vendor email", %{conn: conn, password: password, vendor: vendor} do
      new_email = unique_vendor_email()

      {:ok, lv, _html} = live(conn, ~p"/vendors/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "vendor" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_vendor_by_email(vendor.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/vendors/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "vendor" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, vendor: vendor} do
      {:ok, lv, _html} = live(conn, ~p"/vendors/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "vendor" => %{"email" => vendor.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_vendor_password()
      vendor = vendor_fixture(%{password: password})
      %{conn: log_in_vendor(conn, vendor), vendor: vendor, password: password}
    end

    test "updates the vendor password", %{conn: conn, vendor: vendor, password: password} do
      new_password = valid_vendor_password()

      {:ok, lv, _html} = live(conn, ~p"/vendors/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "vendor" => %{
            "email" => vendor.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/vendors/settings"

      assert get_session(new_password_conn, :vendor_token) != get_session(conn, :vendor_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_vendor_by_email_and_password(vendor.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/vendors/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "vendor" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/vendors/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "vendor" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      vendor = vendor_fixture()
      email = unique_vendor_email()

      token =
        extract_vendor_token(fn url ->
          Accounts.deliver_vendor_update_email_instructions(
            %{vendor | email: email},
            vendor.email,
            url
          )
        end)

      %{conn: log_in_vendor(conn, vendor), token: token, email: email, vendor: vendor}
    end

    test "updates the vendor email once", %{
      conn: conn,
      vendor: vendor,
      token: token,
      email: email
    } do
      {:error, redirect} = live(conn, ~p"/vendors/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/vendors/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_vendor_by_email(vendor.email)
      assert Accounts.get_vendor_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/vendors/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/vendors/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, vendor: vendor} do
      {:error, redirect} = live(conn, ~p"/vendors/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/vendors/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_vendor_by_email(vendor.email)
    end

    test "redirects if vendor is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/vendors/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/vendors/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
