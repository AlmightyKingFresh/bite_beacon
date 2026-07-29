defmodule BiteBeacon.Repo.Migrations.FixUniqueIndexForVendors do
  use Ecto.Migration

  def change do
    drop unique_index(:vendors, [:email, :permit_id])
    create unique_index(:vendors, [:email])
    create unique_index(:vendors, [:permit_id])
  end
end
