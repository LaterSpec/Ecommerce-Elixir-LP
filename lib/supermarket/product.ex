defmodule Supermarket.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :sku, :integer
    field :category, :string
    field :price, :integer
    field :active, :boolean, default: true
    
    has_many :stock_items, Supermarket.Inventory.StockItem

    has_many :cart_items, Supermarket.Cart.CartItem
    
    timestamps()
  end

  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :sku, :category, :price, :active])
    |> validate_required([:name, :sku, :category, :price])
    |> validate_number(:sku, greater_than: 0)
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> unique_constraint(:sku)
  end
end