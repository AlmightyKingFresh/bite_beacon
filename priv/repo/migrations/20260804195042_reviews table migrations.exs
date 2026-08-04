defmodule :"Elixir.BiteBeacon.Repo.Migrations.Reviews table migrations" do
  use Ecto.Migration

  def change do
    create table(:reviews) do
      add :facility_id, references(:facilities, on_delete: :delete_all)
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :rating, :integer
      add :comment, :text

      timestamps()
    end

    create unique_index(:reviews, [:facility_id, :user_id])
  end
end
