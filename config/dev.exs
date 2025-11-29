import Config

config :mi_tienda_web, MiTiendaWeb.Repo,
  username: "postgres",
  password: "********",
  hostname: "34.46.167.102",
  database: "supermarket_dev",
  port: 5432,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  ssl: [verify: :verify_none]

config :mi_tienda_web, MiTiendaWebWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4000")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "31cwlZ1EGTPNTG8fiwyqfgwSrp3gtIUn15AYToNpAHvVDkTAWPuyNOBjjDmmF08C",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:mi_tienda_web, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:mi_tienda_web, ~w(--watch)]}
  ]

config :mi_tienda_web, MiTiendaWebWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/mi_tienda_web_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$"
    ]
  ]

config :mi_tienda_web, dev_routes: true

config :logger, :default_formatter, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true,
  enable_expensive_runtime_checks: true

config :swoosh, :api_client, false
