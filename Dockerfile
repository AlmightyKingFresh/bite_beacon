# Dev-only image. Runs the app straight from source (bind-mounted via
# docker-compose) with live reload, rather than building a release.
FROM elixir:1.16.0

RUN apt-get update -y && apt-get install -y \
    build-essential \
    inotify-tools \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app

ENV MIX_ENV=dev

# Install deps separately so this layer is cached unless mix.exs/mix.lock change.
COPY mix.exs mix.lock ./
RUN mix deps.get

COPY . .

RUN chmod +x bin/docker-entrypoint.sh

EXPOSE 4000

ENTRYPOINT ["bin/docker-entrypoint.sh"]
