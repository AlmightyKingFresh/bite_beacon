defmodule Fixtures do
  @moduledoc """
  this module handles dumping the csv into the facility and vendor tables
  and it seeds review data along with creating users
  """
  import Ecto.Query, warn: false

  alias BiteBeacon.Vendors.Vendor
  alias BiteBeacon.Facilities.Facility
  alias BiteBeacon.Reviews.Review
  alias BiteBeacon.Users.User
  alias BiteBeacon.Repo
  alias NimbleCSV.RFC4180, as: CSV
  alias Faker.{Internet, Person}

  require Timex

  @reviewer_count 25

  @rating_weights [{5, 40}, {4, 25}, {3, 15}, {2, 10}, {1, 10}]

  @review_snippets %{
    high: [
      "Best tacos in the city, hands down.",
      "Absolutely delicious, will be back every week.",
      "Line was worth every minute of the wait.",
      "Friendly staff and even better food.",
      "My new go-to lunch spot.",
      "Fresh ingredients, huge portions, fair prices.",
      "Everything I ordered was perfect.",
      "Hidden gem, so glad I found this truck.",
      "Consistently great every single time.",
      "Highly recommend to anyone in the area."
    ],
    mid: [
      "Decent food, service was a bit slow.",
      "Good but a little overpriced for the portion.",
      "Solid option, nothing to write home about.",
      "Tasty, though it could use more seasoning.",
      "Pretty average, might try again eventually.",
      "Fine for a quick bite, not a destination trip.",
      "Good flavor but inconsistent between visits.",
      "It's okay, wouldn't go out of my way for it."
    ],
    low: [
      "Waited 40 minutes for cold food.",
      "Wouldn't go back honestly.",
      "Order was wrong and no one seemed to care.",
      "Way overpriced for what you actually get.",
      "Food was bland and the service was worse.",
      "Disappointing compared to the reviews I read.",
      "Not worth the wait or the price."
    ]
  }

  # @facilty_info "test/support/fixtures/Mobile Food Facility Permit.csv"

  def data_dump() do
    with {:ok, formatted_data} <- format_data(),
         {:ok, _} <- dump_vendors(formatted_data),
         {:ok, _} <- dump_facilities(formatted_data),
         {:ok, _} <- seed_reviews() do
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
          email: Internet.safe_email(),
          # all passwords for fixture data are the same
          password: "Pa$$word",
          permit_id: map["permit_id"],
          permit_status: map["permit_status"],
          name: map["name"],
          # formatted to utc for db insertion
          permit_approval_date: to_utc(map["permit_approval_date"], :long),
          permit_application_received: to_utc(map["permit_application_received"], :short),
          permit_expiration_date: to_utc(map["permit_expiration_date"], :long),
          date_notice_of_intent_sent: nil,
          prior_permit: String.to_integer(map["prior_permit"]),
          type: map["type"],
          cnn: fix_int(map["cnn"]),
          location_description: map["location_description"],
          address: map["address"],
          block_lot: map["block_lot"],
          block: map["block"],
          lot: map["lot"],
          cuisine: map["cuisine"],
          x: fix_float(map["x"]),
          y: fix_float(map["y"]),
          latitude: fix_float(map["latitude"]),
          longitude: fix_float(map["longitude"]),
          schedule_url: map["schedule_url"],
          schedule: map["schedule"],
          location: map["location"],
          fire_prevention_districts: fix_int(map["fire_prevention_districts"]),
          police_districts: fix_int(map["police_districts"]),
          supervisor_districts: fix_int(map["supervisor_districts"]),
          zip_codes: fix_int(map["zip_codes"]),
          neighborhoods: fix_int(map["neighborhoods"]),
          id: fix_int(map["facility_id"]),
          first_name: Person.first_name(),
          last_name: Person.last_name()
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
      {:ok, result} -> {:ok, "All #{Enum.count(result)} facilities dumped successfully"}
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

  @doc """
  Seeds a pool of fake reviewer users and generates realistic, randomly-timed
  reviews across every facility currently in the database. Meant to be run
  after `data_dump/0`, since it depends on facilities already existing.
  """
  def seed_reviews() do
    reviewer_ids = create_fake_reviewers()
    facility_ids = Repo.all(from(f in Facility, select: f.id))

    entries =
      for facility_id <- facility_ids, reduce: [] do
        acc ->
          reviewers = Enum.take_random(reviewer_ids, review_count_for_facility())

          new_entries =
            for user_id <- reviewers do
              rating = weighted_rating()
              timestamp = random_timestamp()

              %{
                facility_id: facility_id,
                user_id: user_id,
                rating: rating,
                body: maybe_review_body(rating),
                inserted_at: timestamp,
                updated_at: timestamp
              }
            end

          new_entries ++ acc
      end

    {count, _} = Repo.insert_all(Review, entries)
    {:ok, "#{count} fake reviews inserted"}
  end

  defp create_fake_reviewers() do
    multi =
      1..@reviewer_count
      |> Enum.reduce(Ecto.Multi.new(), fn index, multi_acc ->
        changeset =
          User.registration_changeset(%User{}, %{
            email: Internet.safe_email(),
            name: Person.name(),
            password: "Pa$$word"
          })

        Ecto.Multi.insert(multi_acc, "insert_reviewer_#{index}", changeset)
      end)

    {:ok, result} = Repo.transaction(multi)

    result
    |> Map.values()
    |> Enum.map(& &1.id)
  end

  defp review_count_for_facility() do
    Enum.random([0, 0, 0, 1, 1, 2, 3, 5, 8])
  end

  defp weighted_rating() do
    @rating_weights
    |> Enum.flat_map(fn {rating, weight} -> List.duplicate(rating, weight) end)
    |> Enum.random()
  end

  defp maybe_review_body(rating) do
    # roughly 30% of reviews are star-only, matching real-world review behavior
    if :rand.uniform(10) <= 3 do
      nil
    else
      bucket =
        cond do
          rating >= 4 -> :high
          rating == 3 -> :mid
          true -> :low
        end

      Enum.random(@review_snippets[bucket])
    end
  end

  defp random_timestamp() do
    days_ago = Enum.random(0..365)
    seconds_into_day = Enum.random(0..86_399)
    seconds_ago = days_ago * 86_400 + seconds_into_day

    DateTime.utc_now()
    |> DateTime.add(-seconds_ago, :second)
    |> DateTime.truncate(:second)
  end

  def clean_tables() do
    Repo.delete_all(Review)
    Repo.delete_all(Vendor)
    Repo.delete_all(Facility)
    Repo.delete_all(User)
  end
end
