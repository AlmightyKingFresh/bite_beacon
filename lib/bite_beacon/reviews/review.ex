defmodule BiteBeacon.Reviews.Review do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reviews" do
    field :rating, :integer
    field :body, :string
    belongs_to :facility, BiteBeacon.Facilities.Facility
    belongs_to :user, BiteBeacon.Users.User, type: :binary_id
    timestamps(type: :utc_datetime)
  end

  def review_changeset(review, attrs \\ %{}) do
    review
    |> cast(attrs, [:facility_id, :user_id, :rating, :body])
    |> validate_required([:facility_id, :user_id, :rating])
    |> validate_body_length()
    |> validate_rating()
    |> unique_constraint([:facility_id, :user_id])
    |> foreign_key_constraint(:facility_id)
    |> foreign_key_constraint(:user_id)
  end

  defp validate_body_length(changeset) do
    changeset
    |> validate_length(:body, max: 285)
  end

  defp validate_rating(changeset) do
    changeset
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
  end
end
