defmodule BiteBeacon.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias BiteBeacon.Repo

  alias BiteBeacon.Accounts.{User, UserToken, UserNotifier}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  alias BiteBeacon.Accounts.{Vendor, VendorToken, VendorNotifier}

  ## Database getters

  @doc """
  Gets a vendor by email.

  ## Examples

      iex> get_vendor_by_email("foo@example.com")
      %Vendor{}

      iex> get_vendor_by_email("unknown@example.com")
      nil

  """
  def get_vendor_by_email(email) when is_binary(email) do
    Repo.get_by(Vendor, email: email)
  end

  @doc """
  Gets a vendor by email and password.

  ## Examples

      iex> get_vendor_by_email_and_password("foo@example.com", "correct_password")
      %Vendor{}

      iex> get_vendor_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_vendor_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    vendor = Repo.get_by(Vendor, email: email)
    if Vendor.valid_password?(vendor, password), do: vendor
  end

  @doc """
  Gets a single vendor.

  Raises `Ecto.NoResultsError` if the Vendor does not exist.

  ## Examples

      iex> get_vendor!(123)
      %Vendor{}

      iex> get_vendor!(456)
      ** (Ecto.NoResultsError)

  """
  def get_vendor!(id), do: Repo.get!(Vendor, id)

  ## Vendor registration

  @doc """
  Registers a vendor.

  ## Examples

      iex> register_vendor(%{field: value})
      {:ok, %Vendor{}}

      iex> register_vendor(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_vendor(attrs) do
    %Vendor{}
    |> Vendor.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking vendor changes.

  ## Examples

      iex> change_vendor_registration(vendor)
      %Ecto.Changeset{data: %Vendor{}}

  """
  def change_vendor_registration(%Vendor{} = vendor, attrs \\ %{}) do
    Vendor.registration_changeset(vendor, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the vendor email.

  ## Examples

      iex> change_vendor_email(vendor)
      %Ecto.Changeset{data: %Vendor{}}

  """
  def change_vendor_email(vendor, attrs \\ %{}) do
    Vendor.email_changeset(vendor, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_vendor_email(vendor, "valid password", %{email: ...})
      {:ok, %Vendor{}}

      iex> apply_vendor_email(vendor, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_vendor_email(vendor, password, attrs) do
    vendor
    |> Vendor.email_changeset(attrs)
    |> Vendor.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the vendor email using the given token.

  If the token matches, the vendor email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_vendor_email(vendor, token) do
    context = "change:#{vendor.email}"

    with {:ok, query} <- VendorToken.verify_change_email_token_query(token, context),
         %VendorToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(vendor_email_multi(vendor, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp vendor_email_multi(vendor, email, context) do
    changeset =
      vendor
      |> Vendor.email_changeset(%{email: email})
      |> Vendor.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:vendor, changeset)
    |> Ecto.Multi.delete_all(:tokens, VendorToken.by_vendor_and_contexts_query(vendor, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given vendor.

  ## Examples

      iex> deliver_vendor_update_email_instructions(vendor, current_email, &url(~p"/vendors/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_vendor_update_email_instructions(
        %Vendor{} = vendor,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, vendor_token} =
      VendorToken.build_email_token(vendor, "change:#{current_email}")

    Repo.insert!(vendor_token)
    VendorNotifier.deliver_update_email_instructions(vendor, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the vendor password.

  ## Examples

      iex> change_vendor_password(vendor)
      %Ecto.Changeset{data: %Vendor{}}

  """
  def change_vendor_password(vendor, attrs \\ %{}) do
    Vendor.password_changeset(vendor, attrs, hash_password: false)
  end

  @doc """
  Updates the vendor password.

  ## Examples

      iex> update_vendor_password(vendor, "valid password", %{password: ...})
      {:ok, %Vendor{}}

      iex> update_vendor_password(vendor, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_vendor_password(vendor, password, attrs) do
    changeset =
      vendor
      |> Vendor.password_changeset(attrs)
      |> Vendor.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:vendor, changeset)
    |> Ecto.Multi.delete_all(:tokens, VendorToken.by_vendor_and_contexts_query(vendor, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{vendor: vendor}} -> {:ok, vendor}
      {:error, :vendor, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_vendor_session_token(vendor) do
    {token, vendor_token} = VendorToken.build_session_token(vendor)
    Repo.insert!(vendor_token)
    token
  end

  @doc """
  Gets the vendor with the given signed token.
  """
  def get_vendor_by_session_token(token) do
    {:ok, query} = VendorToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_vendor_session_token(token) do
    Repo.delete_all(VendorToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given vendor.

  ## Examples

      iex> deliver_vendor_confirmation_instructions(vendor, &url(~p"/vendors/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_vendor_confirmation_instructions(confirmed_vendor, &url(~p"/vendors/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_vendor_confirmation_instructions(%Vendor{} = vendor, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if vendor.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, vendor_token} = VendorToken.build_email_token(vendor, "confirm")
      Repo.insert!(vendor_token)

      VendorNotifier.deliver_confirmation_instructions(
        vendor,
        confirmation_url_fun.(encoded_token)
      )
    end
  end

  @doc """
  Confirms a vendor by the given token.

  If the token matches, the vendor account is marked as confirmed
  and the token is deleted.
  """
  def confirm_vendor(token) do
    with {:ok, query} <- VendorToken.verify_email_token_query(token, "confirm"),
         %Vendor{} = vendor <- Repo.one(query),
         {:ok, %{vendor: vendor}} <- Repo.transaction(confirm_vendor_multi(vendor)) do
      {:ok, vendor}
    else
      _ -> :error
    end
  end

  defp confirm_vendor_multi(vendor) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:vendor, Vendor.confirm_changeset(vendor))
    |> Ecto.Multi.delete_all(
      :tokens,
      VendorToken.by_vendor_and_contexts_query(vendor, ["confirm"])
    )
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given vendor.

  ## Examples

      iex> deliver_vendor_reset_password_instructions(vendor, &url(~p"/vendors/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_vendor_reset_password_instructions(%Vendor{} = vendor, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, vendor_token} = VendorToken.build_email_token(vendor, "reset_password")
    Repo.insert!(vendor_token)

    VendorNotifier.deliver_reset_password_instructions(
      vendor,
      reset_password_url_fun.(encoded_token)
    )
  end

  @doc """
  Gets the vendor by reset password token.

  ## Examples

      iex> get_vendor_by_reset_password_token("validtoken")
      %Vendor{}

      iex> get_vendor_by_reset_password_token("invalidtoken")
      nil

  """
  def get_vendor_by_reset_password_token(token) do
    with {:ok, query} <- VendorToken.verify_email_token_query(token, "reset_password"),
         %Vendor{} = vendor <- Repo.one(query) do
      vendor
    else
      _ -> nil
    end
  end

  @doc """
  Resets the vendor password.

  ## Examples

      iex> reset_vendor_password(vendor, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Vendor{}}

      iex> reset_vendor_password(vendor, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_vendor_password(vendor, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:vendor, Vendor.password_changeset(vendor, attrs))
    |> Ecto.Multi.delete_all(:tokens, VendorToken.by_vendor_and_contexts_query(vendor, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{vendor: vendor}} -> {:ok, vendor}
      {:error, :vendor, changeset, _} -> {:error, changeset}
    end
  end
end
