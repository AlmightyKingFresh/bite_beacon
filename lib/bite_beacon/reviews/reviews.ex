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
  A user can update their review of a facility,
  but not if it's been less than 24 hours since the last review/update.
  """

  @spec update_review(Review.t(), map()) ::
          {:ok, Review.t()}
          | {:error, Ecto.Changeset.t() | :review_not_found | :too_soon_since_last_review}
  def update_review(%Review{} = review, attrs) do
    with {:ok, review} <- review_cooldown(review) do
      review
      |> Review.review_changeset(attrs)
      |> Repo.update()
    end
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

  defp review_cooldown(%Review{updated_at: updated_at} = review) do
    hours_since_update = DateTime.diff(DateTime.utc_now(), updated_at, :hour)

    if hours_since_update < 24 do
      {:error, :too_soon_since_last_review}
    else
      {:ok, review}
    end
  end
end
