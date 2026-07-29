defmodule BiteBeacon.Repo.Migrations.CreateFacilities do
  use Ecto.Migration

  def change do
    create table(:facilities, primary_key: false) do
      add :id, :bigint, primary_key: true, autoincrement: true
      add :vendor_id, references(:vendors, type: :binary_id, on_delete: :delete_all), null: false
      add :permit_id, :string
      add :type, :string
      add :cnn, :integer
      add :location_description, :string
      add :address, :string
      add :block_lot, :string
      add :block, :string
      add :lot, :string
      add :cuisine, :string, size: 500
      add :x, :float
      add :y, :float
      add :latitude, :float
      add :longitude, :float
      add :schedule_url, :string
      add :schedule, :string
      add :location, :string
      add :fire_prevention_districts, :integer
      add :police_districts, :integer
      add :supervisor_districts, :integer
      add :zip_codes, :integer
      add :neighborhoods, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:facilities, [:permit_id])
  end
end
