# BiteBeacon

## Running with Docker (recommended)

  * Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
  * Run `docker-compose up --build`

That's it — Postgres, migrations, and seeding the vendor/facility fixture
data all happen automatically. Visit [`localhost:4000`](http://localhost:4000)
once you see the Phoenix server start in the logs.

## Running without Docker

To start your Phoenix server:

  * Have Postgres running locally (see `config/dev.exs` for expected
    username/password/database, or override via `POSTGRES_*` env vars)
  * Run `mix setup` to install and setup dependencies
  * Run `mix run -e "Fixtures.data_dump()"` to seed the vendor/facility data
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
