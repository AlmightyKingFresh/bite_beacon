defmodule BiteBeacon.Repo do
  use Ecto.Repo,
    otp_app: :bite_beacon,
    adapter: Ecto.Adapters.Postgres
end
