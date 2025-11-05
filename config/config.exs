import Config

# Dile a Ecto qué repos usa tu app
config :supermarket, ecto_repos: [Supermarket.Repo]

# Carga el archivo según el MIX_ENV (dev/test/prod)
import_config "#{Mix.env()}.exs"
