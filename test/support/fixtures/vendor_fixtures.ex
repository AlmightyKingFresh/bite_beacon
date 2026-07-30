defmodule BiteBeacon.VendorFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BiteBeacon.Vendors.Vendor and `BiteBeacon.Users.User contexts.
  """

  def unique_vendor_email, do: "vendor#{System.unique_integer()}@example.com"
  def valid_vendor_password, do: "hello world!"

  def valid_vendor_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_vendor_email(),
      password: valid_vendor_password()
    })
  end

  def vendor_fixture(attrs \\ %{}) do
    {:ok, vendor} =
      attrs
      |> valid_vendor_attributes()
      |> BiteBeacon.Vendors.Vendor.register_vendor()

    vendor
  end

  def extract_vendor_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
