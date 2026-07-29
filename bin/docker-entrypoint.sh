#!/bin/sh
set -e

echo "Waiting for postgres at ${POSTGRES_HOST:-localhost}..."
until pg_isready -h "${POSTGRES_HOST:-localhost}" -U "${POSTGRES_USER:-postgres}" -q; do
  sleep 1
done

mix deps.get
mix ecto.create
mix ecto.migrate

mix run -e '
  case BiteBeacon.Food_Facilities.list_facilities() do
    [] ->
      IO.puts("No facilities found, seeding fixture data...")
      {:ok, msg} = Fixtures.data_dump()
      IO.puts(msg)

    facilities ->
      IO.puts("Found #{Enum.count(facilities)} facilities already, skipping seed.")
  end
'

mix assets.setup
mix assets.build

exec mix phx.server
