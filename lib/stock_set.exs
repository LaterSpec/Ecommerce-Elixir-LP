# Ejecutar:
#   elixir lib/stock_set.exs 10003 25

Mix.install([{:ecto_sql, "~> 3.10"}, {:postgrex, ">= 0.0.0"}])

defmodule Supermarket.Repo do
  use Ecto.Repo, otp_app: :supermarket, adapter: Ecto.Adapters.Postgres
end

Application.put_env(:supermarket, Supermarket.Repo,
  username: "postgres", password: "Figu_dev_1", hostname: "34.46.167.102",
  database: "supermarket_dev", port: 5432, pool_size: 5,
  ssl: [verify: :verify_none])

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
    field :quantity, :integer, default: 0
    belongs_to :product, Supermarket.Product
    timestamps()
  end
  def changeset(si, attrs) do
    si |> cast(attrs, [:quantity, :product_id]) |> validate_required([:quantity, :product_id])
  end
end

{:ok, _} = Supermarket.Repo.start_link()
alias Supermarket.{Repo, Product}
alias Supermarket.Inventory.StockItem

case System.argv() do
  [sku_str, qty_str] ->
    with {sku, ""} <- Integer.parse(sku_str),
         {qty, ""} <- Integer.parse(qty_str),
         true <- qty >= 0 do

      case Repo.get_by(Product, sku: sku) do
        nil ->
          IO.puts("❌ Producto con SKU #{sku} no existe.")
        product ->
          pid = product.id
          name = product.name
          
          # Usar struct/2 en lugar de %StockItem{...}
          si = Repo.get_by(StockItem, product_id: pid) || struct(StockItem, product_id: pid, quantity: 0)
          changeset = StockItem.changeset(si, %{quantity: qty, product_id: pid})
          
          case (si.id && Repo.update(changeset)) || Repo.insert(changeset) do
            {:ok, _} ->
              IO.puts("✅ Stock de #{name} (SKU #{sku}) actualizado a #{qty}.")
            {:error, ch} ->
              IO.puts("❌ No se pudo actualizar: #{inspect(ch.errors)}")
          end
      end
    else
      _ ->
        IO.puts("Uso: elixir lib/stock_set.exs <sku_int> <cantidad>=0")
    end

  _ ->
    IO.puts("Uso: elixir lib/stock_set.exs <sku_int> <cantidad>=0")
end