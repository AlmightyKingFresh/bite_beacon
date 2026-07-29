defmodule BiteBeacon.Repo.Migrations.FixNoiForVendors do
  use Ecto.Migration

  def change do
    alter table(:vendors) do
      remove :date_notice_of_intent_sent
      add :date_notice_of_intent_sent, :utc_datetime
    end
  end
end
