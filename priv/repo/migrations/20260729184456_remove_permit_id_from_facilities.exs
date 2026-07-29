defmodule BiteBeacon.Repo.Migrations.RemovePermitIdFromFacilities do
  use Ecto.Migration

  def change do
    alter table(:facilities) do
      remove :permit_id
    end
  end
end
