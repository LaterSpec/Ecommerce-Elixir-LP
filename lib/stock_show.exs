# Ejecutar:
#   elixir lib/stock_show.exs            # lista todos con stock
#   elixir lib/stock_show.exs 10003      # muestra solo ese SKU

Mix.install([
  {:ecto, "~> 3.10"},
  {:ecto_sql, "~> 3.10"},
  {:postgrex, ">= 0.0.0"}
])

defmodule Supermarket.Repo do
  use Ecto.Repo, otp_app: :supermarket, adapter: Ecto.Adapters.Postgres
end

Application.put_env(:supermarket, Supermarket.Repo,
  username: "postgres", password: "12345", hostname: "localhost",
  database: "supermarket_dev", port: 5432, pool_size: 5
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
  schema "stock_items" do
    field :quantity, :integer, default: 0
    belongs_to :product, Supermarket.Product
    timestamps()
  end
end

defmodule Supermarket.StockShow do
  import Ecto.Query  # <-- MOVIDO AQUÍ
  alias Supermarket.{Repo, Product}
  alias Supermarket.Inventory.StockItem

  def run(args) do
    query =
      from p in Product,
        left_join: si in StockItem, on: si.product_id == p.id,
        select: {p.sku, p.name, p.category, p.price, coalesce(si.quantity, 0)},
        order_by: [asc: p.sku]

    rows =
      case args do
        [sku_str] ->
          case Integer.parse(sku_str) do
            {sku, ""} ->
              Repo.all(from [p, si] in query, where: p.sku == ^sku)
            _ ->
              IO.puts("❌ SKU debe ser un número entero.")
              []
          end
        _ ->
          Repo.all(query)
      end

    display_results(rows)
  end

  defp display_results([]) do
    IO.puts("📦 Sin productos/stock.")
  end

  defp display_results(rows) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts(String.pad_trailing("SKU", 8) <> 
            String.pad_trailing("Cantidad", 12) <> 
            String.pad_trailing("Categoría", 15) <> 
            String.pad_trailing("Precio", 10) <> 
            "Nombre")
    IO.puts(String.duplicate("=", 80))
    
    Enum.each(rows, fn {sku, name, category, price, qty} ->
      IO.puts(
        String.pad_trailing("#{sku}", 8) <> 
        String.pad_trailing("#{qty}", 12) <> 
        String.pad_trailing("#{category}", 15) <> 
        String.pad_trailing("$#{price}", 10) <> 
        "#{name}"
      )
    end)
    
    IO.puts(String.duplicate("=", 80) <> "\n")
  end
end

{:ok, _} = Supermarket.Repo.start_link()
Supermarket.StockShow.run(System.argv())