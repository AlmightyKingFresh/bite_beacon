defmodule :"Elixir.BiteBeacon.Repo.Migrations.Add name to facilities" do
  use Ecto.Migration

  def change do
    alter table(:facilities) do
      add :name, :string
    end
  end
end
