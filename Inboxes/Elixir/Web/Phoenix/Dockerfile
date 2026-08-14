FROM elixir:1.17-alpine

ENV MIX_ENV=prod
WORKDIR /app

# Native deps needed to compile db drivers on alpine
RUN apk add --no-cache build-base git postgresql-client

COPY src/mix.exs src/mix.lock ./
COPY src/config ./config
RUN mix local.hex --force && mix local.rebar --force && mix deps.get --only prod

COPY src/ .
RUN mix compile

EXPOSE 4000
CMD ["sh", "-c", "mix ecto.migrate && mix phx.server"]