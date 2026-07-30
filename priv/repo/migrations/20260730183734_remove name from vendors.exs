defmodule :"Elixir.BiteBeacon.Repo.Migrations.Remove name from vendors" do
  use Ecto.Migration

  def change do
    alter table(:vendors) do
      remove :name
    end
  end
end
