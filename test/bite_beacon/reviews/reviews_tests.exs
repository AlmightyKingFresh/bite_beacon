defmodule BiteBeacon.Reviews.ReviewsTests do
  @moduledoc """
  Tests for the Reviews context.
  """

  use BiteBeacon.DataCase, async: true

  import BiteBeacon.Factory

  alias BiteBeacon.Repo
  alias BiteBeacon.Reviews.{Review, Reviews}

  describe "Review changeset functions" do
    setup do
      user = insert(:user)
      vendor = insert(:vendor)
      facility = insert(:facility, vendor_id: vendor.id)
      %{user: user, facility: facility}
    end

    test "valid review changeset passes", %{user: user, facility: facility} do
      changeset =
        Review.review_changeset(%Review{}, %{
          user_id: user.id,
          facility_id: facility.id,
          rating: 5,
          body: "Great food!"
        })

      assert changeset.valid?
    end

    test "changeset with rating too low fails", %{user: user, facility: facility} do
      changeset =
        Review.review_changeset(%Review{}, %{
          user_id: user.id,
          facility_id: facility.id,
          rating: 0,
          body: "Bad food!"
        })

      assert not changeset.valid?
      assert errors_on(changeset) == %{rating: ["must be greater than or equal to 1"]}
    end

    test "changeset with rating above 5 fails", %{user: user, facility: facility} do
      changeset =
        Review.review_changeset(%Review{}, %{
          user_id: user.id,
          facility_id: facility.id,
          rating: 6,
          body: "Too spicy!"
        })

      assert not changeset.valid?
      assert errors_on(changeset) == %{rating: ["must be less than or equal to 5"]}
    end

    test "changeset without rating fails", %{user: user, facility: facility} do
      changeset =
        Review.review_changeset(%Review{}, %{
          user_id: user.id,
          facility_id: facility.id
        })

      assert not changeset.valid?
      assert errors_on(changeset) == %{rating: ["can't be blank"]}
    end

    test "changeset with body too long fails", %{user: user, facility: facility} do
      changeset =
        Review.review_changeset(%Review{}, %{
          user_id: user.id,
          facility_id: facility.id,
          rating: 5,
          body: String.duplicate("a", 286)
        })

      assert not changeset.valid?
      assert errors_on(changeset) == %{body: ["should be at most 285 character(s)"]}
    end

    test "changeset without facility_id fails", %{user: user} do
      changeset =
        Review.review_changeset(%Review{}, %{
          user_id: user.id,
          rating: 5,
          body: "Great food!"
        })

      assert not changeset.valid?
      assert errors_on(changeset) == %{facility_id: ["can't be blank"]}
    end

    test "changeset without user_id fails", %{facility: facility} do
      changeset =
        Review.review_changeset(%Review{}, %{
          facility_id: facility.id,
          rating: 5,
          body: "Great food!"
        })

      assert not changeset.valid?
      assert errors_on(changeset) == %{user_id: ["can't be blank"]}
    end
  end

  describe "Review CRUD" do
    setup do
      user = insert(:user)
      vendor = insert(:vendor)
      facility = insert(:facility, vendor_id: vendor.id)
      %{user: user, facility: facility}
    end

    test "create_review/1 creates review if given valid attributes", %{
      user: user,
      facility: facility
    } do
      attrs = %{
        user_id: user.id,
        facility_id: facility.id,
        rating: 5,
        body: "Great food!"
      }

      {:ok, review} = Reviews.create_review(attrs)
      assert review.user_id == user.id
      assert review.facility_id == facility.id
      assert review.rating == 5
      assert review.body == "Great food!"

      assert Repo.get_by!(Review, user_id: user.id) == review
      assert Repo.get_by!(Review, facility_id: facility.id) == review
    end

    test "create_review/1 inserts nothing if the data isn't valid" do
      attrs = %{
        user_id: Ecto.UUID.generate(),
        facility_id: "22",
        rating: 0,
        body: "!!!!!!!!!!"
      }

      reviews_before = Repo.all(Review)

      Reviews.create_review(attrs)

      reviews_after = Repo.all(Review)

      assert reviews_before == reviews_after
    end

    test "get_review/1 returns the review with the given id", %{
      user: user,
      facility: facility
    } do
      attrs = %{
        user_id: user.id,
        facility_id: facility.id,
        rating: 5,
        body: "Great food!"
      }

      {:ok, %Review{id: review_id}} = Reviews.create_review(attrs)
      Reviews.get_review(review_id)
      retrieved_review = Reviews.get_review(review_id)
      assert retrieved_review.id == review_id
      assert retrieved_review.user_id == user.id
      assert retrieved_review.facility_id == facility.id
      assert retrieved_review.rating == 5
      assert retrieved_review.body == "Great food!"
    end

    test "get_review/1 returns nil if the review doesn't exist" do
      assert Reviews.get_review(-1) == nil
    end

    test "get_reviews_for_facility/1 returns reviews for the given facility", %{
      user: user,
      facility: facility
    } do
      user2 = insert(:user)

      review1 =
        insert(:review,
          user_id: user.id,
          facility_id: facility.id,
          rating: 5,
          body: "Great food!"
        )

      review2 =
        insert(:review,
          user_id: user2.id,
          facility_id: facility.id,
          rating: 4,
          body: "Good food!"
        )

      reviews = Reviews.get_reviews_for_facility(facility.id)
      assert review1 in reviews
      assert review2 in reviews
    end

    test "get_reviews_for_facility/1 returns empty list if no reviews exist for the facility", %{
      facility: facility
    } do
      reviews = Reviews.get_reviews_for_facility(facility.id)
      assert reviews == []
    end

    test "get_reviews_for_user/1 returns reviews for the given user", %{
      user: user,
      facility: facility
    } do
      facility2 = insert(:facility)
      facility3 = insert(:facility)

      review1 =
        insert(:review,
          user_id: user.id,
          facility_id: facility.id,
          rating: 5,
          body: "Great food!"
        )

      review2 =
        insert(:review,
          user_id: user.id,
          facility_id: facility2.id,
          rating: 4,
          body: "Good food!"
        )

      review3 =
        insert(:review,
          user_id: user.id,
          facility_id: facility3.id,
          rating: 3,
          body: "Average food!"
        )

      reviews = Reviews.get_reviews_for_user(user.id)
      assert review1 in reviews
      assert review2 in reviews
      assert review3 in reviews
    end

    test "get_reviews_for_user/1 returns empty list if no reviews exist for the user", %{
      user: user
    } do
      reviews = Reviews.get_reviews_for_user(user.id)
      assert reviews == []
    end

    test "update_review/2 updates an existing review", %{
      user: user,
      facility: facility
    } do
      review =
        insert(:review,
          user_id: user.id,
          facility_id: facility.id,
          rating: 5,
          body: "Great food! Better the 2nd time!",
          updated_at: DateTime.utc_now() |> DateTime.add(-45, :hour)
        )

      {:ok, updated_review} = Reviews.update_review(review, %{body: "Better the 2nd time!"})
      assert updated_review.body == "Better the 2nd time!"
      assert updated_review.rating == 5
      assert updated_review.user_id == user.id
      assert updated_review.facility_id == facility.id
    end

    test "update_review/2 returns error if review does not exist" do
      assert {:error, :review_not_found} ==
               Reviews.update_review(
                 %Review{
                   id: 999,
                   facility_id: 1_234_567,
                   user_id: Ecto.UUID.generate(),
                   rating: 2,
                   updated_at: DateTime.utc_now() |> DateTime.add(-25, :hour)
                 },
                 %{body: "Non-existent review"}
               )
    end

    test "update_review/2 returns error if it's been less than 24 hours since the last update" do
      review = insert(:review)

      assert {:error, :too_soon_since_last_review} ==
               Reviews.update_review(review, %{body: "Updated review"})
    end

    test "delete_review/1 deletes an existing review", %{
      user: user,
      facility: facility
    } do
      review =
        insert(:review,
          user_id: user.id,
          facility_id: facility.id,
          rating: 5,
          body: "Great food!"
        )

      {:ok, deleted_review} = Reviews.delete_review(review)
      assert deleted_review.id == review.id
      assert Repo.all(Review) == []
    end

    test "delete_review/1 returns error if review does not exist" do
      assert {:error, :review_not_found} ==
               Reviews.delete_review(%Review{
                 id: 999,
                 facility_id: 1_234_567,
                 user_id: Ecto.UUID.generate(),
                 rating: 2
               })
    end

    test "get_rating_average_for_facility/1 returns the average rating for a given facility", %{
      user: user,
      facility: facility
    } do
      user2 = insert(:user)
      user3 = insert(:user)
      insert(:review, user_id: user.id, facility_id: facility.id, rating: 4)
      insert(:review, user_id: user2.id, facility_id: facility.id, rating: 3)
      insert(:review, user_id: user3.id, facility_id: facility.id, rating: 4)

      average_rating = Reviews.get_rating_average_for_facility(facility.id)
      assert average_rating == 3.67
    end

    test "get_rating_average_for_facility/1 returns nil if no reviews exist for the facility", %{
      facility: facility
    } do
      average_rating = Reviews.get_rating_average_for_facility(facility.id)
      assert average_rating == nil
    end

    test "get_rating_average_for_facility/1 returns nil if the facility does not exist" do
      average_rating = Reviews.get_rating_average_for_facility(-1)
      assert average_rating == nil
    end

    test "get_five_most_recent_reviews_for_facility/1 returns the five most recent reviews for a given facility",
         %{
           user: user,
           facility: facility
         } do
      user2 = insert(:user)
      user3 = insert(:user)
      user4 = insert(:user)
      user5 = insert(:user)
      user6 = insert(:user)

      review1 =
        insert(:review,
          user_id: user.id,
          facility_id: facility.id,
          rating: 4,
          body: "Good food!",
          inserted_at: ~N[2023-01-01 00:00:00]
        )

      review2 =
        insert(:review,
          user_id: user2.id,
          facility_id: facility.id,
          body: "Average food!",
          rating: 3,
          inserted_at: ~N[2023-01-02 00:00:00]
        )

      review3 =
        insert(:review,
          user_id: user3.id,
          facility_id: facility.id,
          body: "Great food!",
          rating: 4,
          inserted_at: ~N[2023-01-03 00:00:00]
        )

      review4 =
        insert(:review,
          user_id: user4.id,
          facility_id: facility.id,
          body: "Excellent food!",
          rating: 5,
          inserted_at: ~N[2023-01-04 00:00:00]
        )

      review5 =
        insert(:review,
          user_id: user5.id,
          facility_id: facility.id,
          body: "Not good!",
          rating: 2,
          inserted_at: ~N[2023-01-05 00:00:00]
        )

      review6 =
        insert(:review,
          user_id: user6.id,
          facility_id: facility.id,
          body: "Terrible food!",
          rating: 1,
          inserted_at: ~N[2023-01-06 00:00:00]
        )

      recent_reviews = Reviews.get_five_most_recent_reviews_for_facility(facility.id)

      assert review1 not in recent_reviews
      assert recent_reviews == [review6, review5, review4, review3, review2]
    end

    test "get_five_most_recent_reviews_for_facility/1 returns empty list if no reviews exist for the facility",
         %{
           facility: facility
         } do
      recent_reviews = Reviews.get_five_most_recent_reviews_for_facility(facility.id)
      assert recent_reviews == []
    end

    test "get_five_most_recent_reviews_for_facility/1 returns empty list if the facility does not exist" do
      recent_reviews = Reviews.get_five_most_recent_reviews_for_facility(-1)
      assert recent_reviews == []
    end

    test "get_five_most_recent_reviews_for_facility/1 returns only reviews with non-nil bodies",
         %{
           user: user,
           facility: facility
         } do
      user2 = insert(:user)
      user3 = insert(:user)

      review1 =
        insert(:review,
          user_id: user.id,
          facility_id: facility.id,
          rating: 4,
          body: "Good food!",
          inserted_at: ~N[2023-01-01 00:00:00]
        )

      review2 =
        insert(:review,
          user_id: user2.id,
          facility_id: facility.id,
          body: nil,
          rating: 3,
          inserted_at: ~N[2023-01-02 00:00:00]
        )

      review3 =
        insert(:review,
          user_id: user3.id,
          facility_id: facility.id,
          body: "Great food!",
          rating: 4,
          inserted_at: ~N[2023-01-03 00:00:00]
        )

      recent_reviews = Reviews.get_five_most_recent_reviews_for_facility(facility.id)

      assert review2 not in recent_reviews
      assert recent_reviews == [review3, review1]
    end

    test "get_top_five_reviews_for_facility/1 returns the five highest-rated reviews for a given facility, most recent first as a tiebreaker",
         %{
           user: user,
           facility: facility
         } do
      user2 = insert(:user)
      user3 = insert(:user)
      user4 = insert(:user)
      user5 = insert(:user)
      user6 = insert(:user)

      review1 =
        insert(:review,
          user_id: user.id,
          facility_id: facility.id,
          rating: 5,
          body: "Excellent food!",
          inserted_at: ~N[2023-01-01 00:00:00]
        )

      review2 =
        insert(:review,
          user_id: user2.id,
          facility_id: facility.id,
          rating: 4,
          body: "Good food!",
          inserted_at: ~N[2023-01-02 00:00:00]
        )

      review3 =
        insert(:review,
          user_id: user3.id,
          facility_id: facility.id,
          rating: 5,
          body: "Great food!",
          inserted_at: ~N[2023-01-03 00:00:00]
        )

      review4 =
        insert(:review,
          user_id: user4.id,
          facility_id: facility.id,
          rating: 3,
          body: "Average food!",
          inserted_at: ~N[2023-01-04 00:00:00]
        )

      review5 =
        insert(:review,
          user_id: user5.id,
          facility_id: facility.id,
          rating: 2,
          body: "Not good!",
          inserted_at: ~N[2023-01-05 00:00:00]
        )

      review6 =
        insert(:review,
          user_id: user6.id,
          facility_id: facility.id,
          rating: 5,
          body: "Terrible food!",
          inserted_at: ~N[2023-01-06 00:00:00]
        )

      top_reviews = Reviews.get_top_five_reviews_for_facility(facility.id)

      assert review5 not in top_reviews
      assert top_reviews == [review6, review3, review1, review2, review4]
    end

    test "get_top_five_reviews_for_facility/1 returns empty list if no reviews exist for the facility",
         %{
           facility: facility
         } do
      top_reviews = Reviews.get_top_five_reviews_for_facility(facility.id)
      assert top_reviews == []
    end

    test "get_top_five_reviews_for_facility/1 returns empty list if the facility does not exist" do
      top_reviews = Reviews.get_top_five_reviews_for_facility(-1)
      assert top_reviews == []
    end

    test "get_top_five_reviews_for_facility/1 returns only reviews with non-nil bodies", %{
      user: user,
      facility: facility
    } do
      user2 = insert(:user)
      user3 = insert(:user)

      review1 =
        insert(:review,
          user_id: user.id,
          facility_id: facility.id,
          rating: 5,
          body: "Excellent food!",
          inserted_at: ~N[2023-01-01 00:00:00]
        )

      review2 =
        insert(:review,
          user_id: user2.id,
          facility_id: facility.id,
          rating: 4,
          body: nil,
          inserted_at: ~N[2023-01-02 00:00:00]
        )

      review3 =
        insert(:review,
          user_id: user3.id,
          facility_id: facility.id,
          rating: 5,
          body: "Great food!",
          inserted_at: ~N[2023-01-03 00:00:00]
        )

      top_reviews = Reviews.get_top_five_reviews_for_facility(facility.id)

      assert review2 not in top_reviews
      assert top_reviews == [review3, review1]
    end

    test "get_five_worst_reviews_for_facility/1 returns the five lowest-rated reviews for a given facility, most recent first as a tiebreaker",
         %{
           user: user,
           facility: facility
         } do
      user2 = insert(:user)
      user3 = insert(:user)
      user4 = insert(:user)
      user5 = insert(:user)
      user6 = insert(:user)

      review1 =
        insert(:review,
          user_id: user.id,
          facility_id: facility.id,
          rating: 1,
          body: "Terrible food!",
          inserted_at: ~N[2023-01-01 00:00:00]
        )

      review2 =
        insert(:review,
          user_id: user2.id,
          facility_id: facility.id,
          rating: 2,
          body: "Not good!",
          inserted_at: ~N[2023-01-02 00:00:00]
        )

      review3 =
        insert(:review,
          user_id: user3.id,
          facility_id: facility.id,
          rating: 1,
          body: "Awful food!",
          inserted_at: ~N[2023-01-03 00:00:00]
        )

      review4 =
        insert(:review,
          user_id: user4.id,
          facility_id: facility.id,
          rating: 3,
          body: "Average food!",
          inserted_at: ~N[2023-01-04 00:00:00]
        )

      review5 =
        insert(:review,
          user_id: user5.id,
          facility_id: facility.id,
          rating: 4,
          body: "Good food!",
          inserted_at: ~N[2023-01-05 00:00:00]
        )

      review6 =
        insert(:review,
          user_id: user6.id,
          facility_id: facility.id,
          rating: 1,
          body: "Horrible food!",
          inserted_at: ~N[2023-01-06 00:00:00]
        )

      worst_reviews = Reviews.get_five_worst_reviews_for_facility(facility.id)

      assert review5 not in worst_reviews
      assert worst_reviews == [review6, review3, review1, review2, review4]
    end

    test "get_five_worst_reviews_for_facility/1 returns empty list if no reviews exist for the facility",
         %{
           facility: facility
         } do
      worst_reviews = Reviews.get_five_worst_reviews_for_facility(facility.id)
      assert worst_reviews == []
    end

    test "get_five_worst_reviews_for_facility/1 returns empty list if the facility does not exist" do
      worst_reviews = Reviews.get_five_worst_reviews_for_facility(-1)
      assert worst_reviews == []
    end

    test "get_five_worst_reviews_for_facility/1 returns only reviews with non-nil bodies", %{
      user: user,
      facility: facility
    } do
      user2 = insert(:user)
      user3 = insert(:user)

      review1 =
        insert(:review,
          user_id: user.id,
          facility_id: facility.id,
          rating: 1,
          body: "Terrible food!",
          inserted_at: ~N[2023-01-01 00:00:00]
        )

      review2 =
        insert(:review,
          user_id: user2.id,
          facility_id: facility.id,
          rating: 2,
          body: nil,
          inserted_at: ~N[2023-01-02 00:00:00]
        )

      review3 =
        insert(:review,
          user_id: user3.id,
          facility_id: facility.id,
          rating: 1,
          body: "Awful food!",
          inserted_at: ~N[2023-01-03 00:00:00]
        )

      worst_reviews = Reviews.get_five_worst_reviews_for_facility(facility.id)

      assert review2 not in worst_reviews
      assert worst_reviews == [review3, review1]
    end
  end
end
