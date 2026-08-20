defmodule BiteBeacon.Vendors.Vendor do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "vendors" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime
    field :permit_id, :string
    field :permit_status, :string
    field :permit_approval_date, :utc_datetime
    field :permit_application_received, :utc_datetime
    field :prior_permit, :integer
    field :permit_expiration_date, :utc_datetime
    field :date_notice_of_intent_sent, :utc_datetime
    field :first_name, :string
    field :last_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  A vendor changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(vendor, attrs, opts \\ []) do
    vendor
    |> cast(attrs, [
      :email,
      :password,
      :first_name,
      :last_name,
      :permit_id,
      :permit_status,
      :permit_approval_date,
      :permit_application_received,
      :prior_permit,
      :permit_expiration_date,
      :date_notice_of_intent_sent
    ])
    |> validate_required([:permit_id, :permit_status, :email, :first_name, :last_name, :password])
    |> validate_format(:permit_id, ~r/^\d{2}MFF-\d{4,5}$/,
      message: "must be in the format ##MFF-#### (e.g. 21MFF-00073)"
    )
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_first_name()
    |> validate_last_name()
    |> validate_permit_status()
    |> unique_constraint([:permit_id])
  end

  defp validate_permit_status(changeset) do
    changeset
    |> validate_inclusion(:permit_status, [
      "APPROVED",
      "EXPIRED",
      "REQUESTED",
      "SUSPEND",
      "ISSUED"
    ])
  end

  defp validate_first_name(changeset) do
    changeset
    |> validate_length(:first_name, min: 2, max: 30)
  end

  defp validate_last_name(changeset) do
    changeset
    |> validate_length(:last_name, min: 2, max: 30)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 50)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_length(:password, min: 8, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/,
      message: "at least one digit or punctuation character"
    )
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
    # would keep the database transaction open longer and hurt performance.
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, BiteBeacon.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  def email_changeset(vendor, attrs, opts \\ []) do
    vendor
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  def name_changeset(vendor, attrs) do
    vendor
    |> cast(attrs, [:first_name, :last_name])
    |> validate_length(:first_name, min: 2, max: 30)
    |> validate_length(:last_name, min: 2, max: 30)
  end

  def password_changeset(vendor, attrs, opts \\ []) do
    vendor
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def permit_id_changeset(vendor, attrs) do
    vendor
    |> cast(attrs, [:permit_id])
    |> validate_format(:permit_id, ~r/^\d{2}MFF-\d{4,5}$/,
      message: "must be in the format ##MFF-#### (e.g. 21MFF-00073)"
    )
  end

  def permit_status_changeset(vendor, attrs) do
    vendor
    |> cast(attrs, [:permit_status])
    |> validate_inclusion(:permit_status, [
      "APPROVED",
      "EXPIRED",
      "REQUESTED",
      "SUSPEND",
      "ISSUED"
    ])
  end

  def permit_metadata_changeset(vendor, attrs) do
    vendor
    |> cast(attrs, [
      :permit_approval_date,
      :permit_application_received,
      :permit_expiration_date,
      :date_notice_of_intent_sent
    ])
  end

  def confirm_changeset(vendor) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(vendor, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no vendor or the vendor doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%BiteBeacon.Vendors.Vendor{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
