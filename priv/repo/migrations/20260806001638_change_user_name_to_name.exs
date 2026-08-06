defmodule BiteBeacon.Repo.Migrations.ChangeUserNameToName do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :user_name
      add :name, :string, null: false
    end
  end
end
