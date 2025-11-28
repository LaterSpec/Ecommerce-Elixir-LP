# Ejecutar con:
# elixir lib/init_stock.exs
Mix.install([{:ecto_sql, "~> 3.10"}, {:postgrex, ">= 0.0.0"}])

defmodule Supermarket.Repo do
  use Ecto.Repo, otp_app: :supermarket, adapter: Ecto.Adapters.Postgres
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

defmodule Supermarket.Inventory.StockItem do
  use Ecto.Schema
  import Ecto.Changeset
  
  schema "stock_items" do
    field :quantity, :integer
    belongs_to :product, Supermarket.Product
    timestamps()
  end
  
  def changeset(stock_item, attrs) do
    stock_item
    |> cast(attrs, [:quantity, :product_id])
    |> validate_required([:quantity, :product_id])
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
  end
end

# Módulo separado para la lógica de inicialización
defmodule Supermarket.InitStock do
  alias Supermarket.{Repo, Product}
  alias Supermarket.Inventory.StockItem

  def run do
    IO.puts("⚙️  Inicializando stock (20 unidades por producto existente)...")

    products = Repo.all(Product)

    if Enum.empty?(products) do
      IO.puts("No hay productos en la base de datos. Crea productos primero.")
    else
      Enum.each(products, fn p ->
        case Repo.get_by(StockItem, product_id: p.id) do
          nil ->
            struct(StockItem)
            |> StockItem.changeset(%{product_id: p.id, quantity: 20})
            |> Repo.insert!()
            IO.puts("✅ #{p.name} (SKU #{p.sku}) → stock 20 creado.")

          si ->
            si
            |> StockItem.changeset(%{quantity: 20})
            |> Repo.update!()
            IO.puts("#{p.name} (SKU #{p.sku}) → stock actualizado a 20.")
        end
      end)

      IO.puts("\n🎉 Stock inicializado correctamente.\n")
    end
  end
end

# Iniciar repo y ejecutar
{:ok, _} = Supermarket.Repo.start_link()
Supermarket.InitStock.run()