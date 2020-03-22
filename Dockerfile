# ---- Build Stage ----
FROM elixir:1.9 AS app_builder

# Set environment variables for building the application
ENV MIX_ENV=prod \
  LANG=C.UTF-8 \
  SECRET_KEY_BASE='DZtl1zXzUY9QpWL/ZBZ1mSCLHGW1BN+34wNLfXe04BWPFVB0zIc0iEsOghQ5Pdv+'
# THIS SECRET KEY BASE IS JUST FOR RUNNING THE RELEASE


# Install hex and rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Create the application build directory
RUN mkdir /app
WORKDIR /app

# Copy over all the necessary application files and directories
COPY config ./config
COPY lib ./lib
COPY priv ./priv
COPY mix.exs .
COPY mix.lock .

# Fetch the application dependencies and build the application
RUN mix deps.get
RUN mix deps.compile
RUN mix phx.digest
RUN mix release

# Update later to use alpine
FROM debian:buster AS app

ENV LANG=C.UTF-8

# Install openssl
RUN apt-get update && apt-get install -y openssl

# Copy over the build artifact from the previous step and create a non root user
RUN useradd --create-home app
WORKDIR /home/app
COPY --from=app_builder /app/_build .
RUN chown -R app: ./prod
USER app

# Run the Phoenix app
CMD ["./prod/rel/mmo_game/bin/mmo_game", "start"]
