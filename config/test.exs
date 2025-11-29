import Config

config :mi_tienda_web, MiTiendaWeb.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "mi_tienda_web_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :mi_tienda_web, MiTiendaWebWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "kZWiYdUGcBS8WPUrGxdDPnrrP0SHZiFRUQzeY6uok6Uo1gUUPx3v0VoKXpPHfK83",
  server: false

config :mi_tienda_web, MiTiendaWeb.Mailer, adapter: Swoosh.Adapters.Test

config :swoosh, :api_client, false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  enable_expensive_runtime_checks: true
