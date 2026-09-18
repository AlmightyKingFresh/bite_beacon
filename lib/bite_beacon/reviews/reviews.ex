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

  @spec create_review(map()) :: {:ok, Review.t()} | {:error, Ecto.Changeset.t()}
  def create_review(attrs \\ %{}) do
    %Review{}
    |> Review.review_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single review.
  """

  @spec get_review(integer()) :: Review.t() | nil
  def get_review(id), do: Repo.get(Review, id)

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

  @spec update_review(Review.t(), map()) ::
          {:ok, Review.t()} | {:error, Ecto.Changeset.t() | :review_not_found}
  def update_review(%Review{} = review, attrs) do
    review
    |> Review.review_changeset(attrs)
    |> Repo.update()
  rescue
    Ecto.StaleEntryError -> {:error, :review_not_found}
  end

  @doc """
  Deletes a review.
  """

  @spec delete_review(Review.t()) :: {:ok, Review.t()} | {:error, :review_not_found}
  def delete_review(%Review{} = review) do
    Repo.delete(review)
  rescue
    Ecto.StaleEntryError ->
      {:error, :review_not_found}
  end

  @spec get_rating_average_for_facility(integer()) :: float() | nil
  def get_rating_average_for_facility(facility_id) do
    query =
      from r in Review,
        where: r.facility_id == ^facility_id,
        select: avg(r.rating)

    Repo.one(query)
    |> case do
      nil ->
        nil

      avg ->
        Decimal.round(avg, 2)
        |> Decimal.to_float()
    end
  end
end
