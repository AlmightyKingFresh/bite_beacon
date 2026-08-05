defmodule BiteBeacon.Reviews.Reviews do
  @moduledoc """
  The Reviews context.
  """

  import Ecto.Query, warn: false

  alias BiteBeacon.Repo
  alias BiteBeacon.Reviews.Review
  alias Ecto.UUID

  @doc """
  Creates a review.
  """

  def create_review(attrs \\ %{}) do
    %Review{}
    |> Review.review_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single review.
  """

  @spec get_review!(UUID.t()) :: Review.t()
  def get_review!(id), do: Repo.get!(Review, id)

  @doc """
  gets all reviews for a given facility
  """

  @spec get_reviews_for_facility(integer()) :: [Review.t()]
  def get_reviews_for_facility(facility_id) do
    Repo.all(from r in Review, where: r.facility_id == ^facility_id)
  end

  @doc """
  gets all reviews for a given user
  """

  @spec get_reviews_for_user(UUID.t()) :: [Review.t()]
  def get_reviews_for_user(user_id) do
    Repo.all(from r in Review, where: r.user_id == ^user_id)
  end

  @doc """
  Updates a review.
  """

  def update_review(%Review{} = review, attrs) do
    review
    |> Review.review_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a review.
  """

  def delete_review(%Review{} = review) do
    Repo.delete(review)
  end
end
