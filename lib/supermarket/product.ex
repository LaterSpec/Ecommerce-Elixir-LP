defmodule Supermarket.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :sku, :integer
    field :category, :string
    field :price, :integer # Precio en centavos
    field :active, :boolean, default: true
    
    # === NUEVO CAMPO STOCK ===
    field :stock, :integer, default: 0 

    # Relaciones (las dejamos como estan)
    has_many :stock_items, Supermarket.Inventory.StockItem
    has_many :cart_items, Supermarket.Cart.CartItem

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    # === AGREGAMOS :stock A LA LISTA DE CAST ===
    |> cast(attrs, [:name, :sku, :category, :price, :active, :stock])
    # === AGREGAMOS :stock A LA LISTA DE REQUERIDOS ===
    |> validate_required([:name, :sku, :category, :price, :stock])
    |> validate_number(:price, greater_than: 0)
    |> validate_number(:stock, greater_than_or_equal_to: 0)
    |> unique_constraint(:sku)
  end
end