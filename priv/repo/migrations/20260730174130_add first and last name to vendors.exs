defmodule :"Elixir.BiteBeacon.Repo.Migrations.Add first and last name to vendors" do
  use Ecto.Migration

  def change do
    alter table(:vendors) do
      add :first_name, :string
      add :last_name, :string
    end
  end
end
