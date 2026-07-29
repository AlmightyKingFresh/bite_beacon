defmodule BiteBeacon.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BiteBeacon.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> BiteBeacon.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

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
      |> BiteBeacon.Accounts.register_vendor()

    vendor
  end

  def extract_vendor_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
