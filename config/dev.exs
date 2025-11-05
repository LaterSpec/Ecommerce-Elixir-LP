import Config

config :supermarket, Supermarket.Repo,
  username: "postgres",      # por ejemplo: "postgres"
  password: "12345",   # la contraseña que configuraste
  hostname: "localhost",
  database: "supermarket_dev",
  port: 5432,                            
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :supermarket, ecto_repos: [Supermarket.Repo]
