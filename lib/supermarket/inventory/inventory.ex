defmodule Supermarket.Inventory do
  import Ecto.Query
  alias Supermarket.Repo
  alias Supermarket.Product  
  alias Supermarket.Inventory.StockItem

  # Lee stock por SKU
  def get_stock_by_sku(sku) when is_integer(sku) do
    from(si in StockItem,
      join: p in Product, on: p.id == si.product_id,
      where: p.sku == ^sku,
      select: si.quantity
    )
    |> Repo.one()
    |> case do
      nil -> 0
      q   -> q
    end
  end

  # Setea cantidad exacta por SKU 
  def set_stock_by_sku(sku, qty) when is_integer(sku) and is_integer(qty) and qty >= 0 do
    case Repo.get_by(Product, sku: sku) do
      nil -> 
        {:error, :product_not_found}
      product ->
        pid = product.id
        case Repo.get_by(StockItem, product_id: pid) do
          nil ->
            struct(StockItem)
            |> StockItem.changeset(%{product_id: pid, quantity: qty})
            |> Repo.insert()
          si ->
            si
            |> StockItem.changeset(%{quantity: qty})
            |> Repo.update()
        end
    end
  end

  # Ajusta (+/-) stock por SKU 
  def inc_stock_by_sku(sku, delta) when is_integer(sku) and is_integer(delta) do
    Repo.transaction(fn ->
      case Repo.get_by(Product, sku: sku) do
        nil -> 
          Repo.rollback(:product_not_found)
        product ->
          pid = product.id
          si = Repo.get_by(StockItem, product_id: pid) || struct(StockItem, product_id: pid, quantity: 0)
          new_qty = si.quantity + delta
          if new_qty < 0, do: Repo.rollback(:insufficient_stock)
          changeset = StockItem.changeset(si, %{quantity: new_qty, product_id: pid})
          {:ok, saved} = (si.id && Repo.update(changeset)) || Repo.insert(changeset)
          saved
      end
    end)
  end
end