defmodule Supermarket.Inventory.StockItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stock_items" do
    field :quantity, :integer, default: 0
    belongs_to :product, Supermarket.Product
    timestamps()
  end

  def changeset(stock_item, attrs) do
    stock_item
    |> cast(attrs, [:quantity, :product_id])
    |> validate_required([:quantity, :product_id])
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
    |> unique_constraint(:product_id)
    |> foreign_key_constraint(:product_id)
  end
end
