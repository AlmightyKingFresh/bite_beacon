defmodule BiteBeacon.Facilities.Facility do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}

  schema "facilities" do
    field :type, :string
    field :cnn, :integer
    field :permit_id, :integer
    field :location_description, :string
    field :address, :string
    field :block_lot, :string
    field :block, :string
    field :lot, :string
    field :cuisine, :string
    field :x, :float
    field :y, :float
    field :latitude, :float
    field :longitude, :float
    field :schedule_url, :string
    field :schedule, :string
    field :location, :string
    field :fire_prevention_districts, :integer
    field :police_districts, :integer
    field :supervisor_districts, :integer
    field :zip_codes, :integer
    field :neighborhoods, :integer

    belongs_to :vendor, BiteBeacon.Vendors.Vendor, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(facility, attrs) do
    facility
    |> cast(attrs, [
      :id,
      :type,
      :cnn,
      :location_description,
      :address,
      :block_lot,
      :block,
      :lot,
      :cuisine,
      :x,
      :y,
      :latitude,
      :longitude,
      :schedule_url,
      :schedule,
      :location,
      :fire_prevention_districts,
      :police_districts,
      :supervisor_districts,
      :zip_codes,
      :neighborhoods,
      :vendor_id
    ])
    |> validate_length(:cuisine, max: 500)
    |> validate_required([:vendor_id])
  end
end
