defmodule BiteBeacon.Repo.Migrations.CreateVendorsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:vendors, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :utc_datetime
      add :name, :string, null: false
      add :permit_id, :string, null: false
      add :permit_status, :string
      add :permit_approval_date, :utc_datetime
      add :permit_application_received, :utc_datetime
      add :prior_permit, :integer
      add :permit_expiration_date, :utc_datetime
      add :date_notice_of_intent_sent, :decimal, precision: 10, scale: 2

      timestamps(type: :utc_datetime)
    end

    create unique_index(:vendors, [:email, :permit_id])

    create table(:vendors_tokens) do
      add :vendor_id, references(:vendors, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:vendors_tokens, [:vendor_id])
    create unique_index(:vendors_tokens, [:context, :token])
  end
end
