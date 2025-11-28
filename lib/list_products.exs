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
  password: "Figu_dev_1",
  hostname: "34.46.167.102",
  database: "supermarket_dev",
  port: 5432,
  pool_size: 5,
  ssl: [verify: :verify_none]
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
    query = from p in Product, order_by: [asc: p.sku]
    products = Repo.all(query)

    if Enum.empty?(products) do
      IO.puts("\n No hay productos registrados.\n")
    else
      IO.puts("\n" <> String.duplicate("=", 90))
      IO.puts(
        String.pad_trailing("SKU", 8) <> 
        String.pad_trailing("Categoría", 20) <> 
        String.pad_trailing("Precio", 12) <> 
        String.pad_trailing("Estado", 10) <> 
        "Nombre"
      )
      IO.puts(String.duplicate("=", 90))
      
      Enum.each(products, fn p ->
        estado = if p.active, do: "Activo", else: "Inactivo"
        IO.puts(
          String.pad_trailing("#{p.sku}", 8) <> 
          String.pad_trailing("#{p.category}", 20) <> 
          String.pad_trailing("$#{p.price}", 12) <> 
          String.pad_trailing("#{estado}", 10) <> 
          "#{p.name}"
        )
      end)
      
      IO.puts(String.duplicate("=", 90))
      IO.puts("Total de productos: #{length(products)}\n")
    end
  end
end

Supermarket.CLI.list_products()