Mix.install([
  {:ecto_sql, "~> 3.10"},
  {:postgrex, ">= 0.0.0"}
])

# Módulo del repositorio
defmodule Supermarket.Repo do
  use Ecto.Repo,
    otp_app: :supermarket,
    adapter: Ecto.Adapters.Postgres
end

# Cargar configuración de conexión
Application.put_env(:supermarket, Supermarket.Repo,
  username: "postgres",
  password: "Figu_dev_1",
  hostname: "34.46.167.102",
  database: "supermarket_dev",
  port: 5432,
  pool_size: 5,
  ssl: [verify: :verify_none]
)

# Iniciar conexión
{:ok, _pid} = Supermarket.Repo.start_link()

# Verificar tipos de columnas
IO.puts("Verificando esquema de la tabla products:")
IO.puts("=" |> String.duplicate(60))

query = """
SELECT 
  column_name, 
  data_type, 
  character_maximum_length,
  udt_name
FROM information_schema.columns 
WHERE table_name = 'products'
ORDER BY ordinal_position
"""

result = Ecto.Adapters.SQL.query!(Supermarket.Repo, query, [])

Enum.each(result.rows, fn [column, data_type, max_length, udt_name] ->
  length_info = if max_length, do: " (max: #{max_length})", else: ""
  IO.puts("#{column}: #{data_type}#{length_info} [#{udt_name}]")
end)

IO.puts("=" |> String.duplicate(60))