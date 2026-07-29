defmodule Fixtures do
  @moduledoc """
  this module handles dumping the csv into the vendors and facilities tables
  """
  import Ecto.Query, warn: false

  alias BiteBeacon.Vendors.Vendor
  alias BiteBeacon.FoodFacilities.Facility
  alias BiteBeacon.Repo
  alias NimbleCSV.RFC4180, as: CSV
  alias Faker.Internet, as: Fake

  require Timex
  # @facilty_info "test/support/fixtures/Mobile Food Facility Permit.csv"

  def data_dump() do
    with {:ok, formatted_data} <- format_data(),
         {:ok, _} <- dump_vendors(formatted_data),
         {:ok, _} <- dump_facilities(formatted_data) do
      {:ok, "fixture data dumped successfully"}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp format_data() do
    header_changes = %{
      "Address" => "address",
      "locationid" => "facility_id",
      "Applicant" => "name",
      "FacilityType" => "type",
      "LocationDescription" => "location_description",
      "blocklot" => "block_lot",
      "permit" => "permit_id",
      "Status" => "permit_status",
      "FoodItems" => "cuisine",
      "X" => "x",
      "Y" => "y",
      "Latitude" => "latitude",
      "Longitude" => "longitude",
      "Schedule" => "schedule_url",
      "dayshours" => "schedule",
      "Approved" => "permit_approval_date",
      "Received" => "permit_application_received",
      "PriorPermit" => "prior_permit",
      "ExpirationDate" => "permit_expiration_date",
      "Location" => "location",
      "Fire Prevention Districts" => "fire_prevention_districts",
      "Police Districts" => "police_districts",
      "Supervisor Districts" => "supervisor_districts",
      "Zip Codes" => "zip_codes",
      "NOISent" => "date_notice_of_intent_sent",
      "Neighborhoods (old)" => "neighborhoods"
    }

    mapped_data =
      File.read!("test/support/fixtures/Mobile Food Facility Permit.csv")
      |> CSV.parse_string(skip_headers: false)
      |> Stream.transform(nil, fn
        headers, nil ->
          modified_headers =
            Enum.map(headers, fn header ->
              Map.get(header_changes, header, header)
            end)

          {[], modified_headers}

        row, headers ->
          {[Enum.zip(headers, row) |> Map.new()], headers}
      end)

    formatted_data =
      for map <- mapped_data do
        %{
          email: Fake.safe_email(),
          # all passwords for fixture data are the same
          password: "Pa$$word",
          permit_id: map["permit_id"],
          permit_status: map["permit_status"],
          name: map["name"],
          # formatted to utc for db insertion
          permit_approval_date: to_utc(map["permit_approval_date"], :long),
          # formatted to utc for db insertion
          permit_application_received: to_utc(map["permit_application_received"], :short),
          # formatted to utc for db insertion
          permit_expiration_date: to_utc(map["permit_expiration_date"], :long),
          date_notice_of_intent_sent: nil,
          prior_permit: String.to_integer(map["prior_permit"]),
          type: map["type"],
          cnn: fix_int(map["cnn"]),
          location_descrption: map["location_description"],
          address: map["address"],
          block_lot: map["block_lot"],
          block: map["block"],
          lot: map["lot"],
          cuisine: map["cuisine"],
          x: fix_float(map["x"]),
          y: fix_float(map["y"]),
          latitude: fix_float(map["latitude"]),
          longittude: fix_float(map["longitude"]),
          schedule_url: map["schedule_url"],
          schedule: map["schedule"],
          location: map["location"],
          fire_prevention_districts: fix_int(map["fire_prevention_districts"]),
          police_districts: fix_int(map["police_districts"]),
          supervisor_districts: fix_int(map["supervisor_disticts"]),
          zip_codes: fix_int(map["zip_codes"]),
          neighborhoods: fix_int(map["neighborhoods"]),
          id: fix_int(map["facility_id"])
        }
      end

    {:ok, formatted_data}
  end

  def dump_vendors(data) do
    vendors_params_list =
      data
      |> Enum.uniq_by(fn map -> map.permit_id end)

    multi = Ecto.Multi.new()

    multi =
      vendors_params_list
      |> Enum.with_index()
      |> Enum.reduce(multi, fn {vendor_params, index}, multi_acc ->
        changeset = Vendor.registration_changeset(%Vendor{}, vendor_params)

        if changeset.valid? do
          Ecto.Multi.insert(multi_acc, "insert_vendor_#{index}", changeset)
        else
          Ecto.Multi.error(multi_acc, "invalid_vendor_#{index}", changeset)
        end
      end)

    case Repo.transaction(multi) do
      {:ok, _result} -> {:ok, "All vendors inserted successfully"}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  defp dump_facilities(data) do
    vendors =
      Vendor
      |> select([vendor], %{vendor_id: vendor.id, permit_id: vendor.permit_id})
      |> Repo.all()

    facilities_params_list =
      for vendor <- vendors, facility <- data, reduce: [] do
        acc ->
          if vendor.permit_id == facility.permit_id do
            [Map.put(facility, :vendor_id, vendor.vendor_id) | acc]
          else
            acc
          end
      end
      |> Enum.uniq_by(& &1.id)

    multi = Ecto.Multi.new()

    multi =
      facilities_params_list
      |> Enum.with_index()
      |> Enum.reduce(multi, fn {facility_params, index}, multi_acc ->
        changeset = Facility.registration_changeset(%Facility{}, facility_params)

        if changeset.valid? do
          Ecto.Multi.insert(multi_acc, "insert_facility_#{index}", changeset)
        else
          Ecto.Multi.error(multi_acc, "invalid_facility_#{index}", changeset)
        end
      end)

    case Repo.transaction(multi) do
      {:ok, result} -> {:ok, "All #{Enum.count(result)} facilites dumped successfully"}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  # defp to_utc(""), do: ""

  defp to_utc(date_string, :long) do
    date_format = "{0M}/{0D}/{YYYY} {h12}:{m}:{s} {AM}"

    case Timex.parse(date_string, date_format) do
      {:ok, datetime} ->
        Timex.to_datetime(datetime, "Etc/UTC")

      {:error, _reason} ->
        ""
    end
  end

  defp to_utc(date_string, :short) do
    date_format = "{YYYY}{0M}{0D}"

    case Timex.parse(date_string, date_format) do
      {:ok, date} ->
        Timex.to_datetime(date, "Etc/UTC")

      {:error, _reason} ->
        ""
    end
  end

  # im squeemish about deleting this function, for some reason it feels like it
  # might be useful in the future, so im leaving it here for now
  # defp to_utc(date_string) do
  #   date_format = "{D}/{M}/{YYYY}"

  #   case Timex.parse(date_string, date_format) do
  #     {:ok, date} ->
  #       Timex.to_datetime(date, "Etc/UTC")

  #     {:error, reason} ->
  #       reason
  #   end
  # end

  defp fix_int(x) when is_nil(x) or x == "", do: nil

  defp fix_int(x) do
    String.to_integer(x)
  end

  defp fix_float(y) when is_nil(y) or y == "" or y == "0", do: nil

  defp fix_float(y) do
    String.to_float(y)
  end

  def clean_tables() do
    Repo.delete_all(Vendor)
    Repo.delete_all(Facility)
  end
end
