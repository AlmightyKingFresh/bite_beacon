defmodule BiteBeacon.Repo.Migrations.RenameCommentToBodyOnReviews do
  use Ecto.Migration

  def change do
    rename table(:reviews), :comment, to: :body
  end
end
