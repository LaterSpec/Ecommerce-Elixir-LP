# Ejecutar con: elixir lib/list_products.exs

Mix.install([
  {:ecto_sql, "~> 3.10"},
  {:postgrex, ">= 0.0.0"}
])

defmodule Supermarket.Repo do
  use Ecto.Repo,
    otp_app: :supermarket,
    adapter: Ecto.Adapters.Postgres
end

Application.put_env(:supermarket, Supermarket.Repo,
  username: "postgres",
  password: "12345",
  hostname: "localhost",
  database: "supermarket_dev",
  port: 5432,
  pool_size: 5
)

defmodule Supermarket.Product do
  use Ecto.Schema

  schema "products" do
    field :name, :string
    field :sku, :integer
    field :category, :string
    field :price, :integer
    field :active, :boolean, default: true
    timestamps()
  end
end

{:ok, _pid} = Supermarket.Repo.start_link()

defmodule Supermarket.CLI do
  import Ecto.Query
  alias Supermarket.{Repo, Product}

  def list_products do
    # Opción 1: usando from/2 (recomendada)
    query = from p in Product, order_by: [asc: p.id]
    products = Repo.all(query)

    if Enum.empty?(products) do
      IO.puts("📦 No hay productos registrados.")
    else
      IO.puts("📋 Lista de productos:\n")
      Enum.each(products, fn p ->
        IO.puts("ID: #{p.id}")
        IO.puts("Nombre: #{p.name}")
        IO.puts("SKU: #{p.sku}")
        IO.puts("Categoría: #{p.category}")
        IO.puts("Precio: $#{p.price}")
        IO.puts("Activo: #{if p.active, do: "Sí", else: "No"}")
        IO.puts("Creado: #{p.inserted_at}")
        IO.puts("-----------------------------")
      end)
    end
  end
end

Supermarket.CLI.list_products()
