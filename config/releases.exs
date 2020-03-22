import Config

config :mmo_game, MmoGameWeb.Endpoint,
  server: true,
  http: [port: {:system, "PORT"}],
  url: [host: "morning-eyrie-68469.herokuapp.com", port: 443]
