defmodule Supermarket.Cart.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cart_items" do
    field :quantity, :integer, default: 1
    belongs_to :user, Supermarket.Accounts.User
    belongs_to :product, Supermarket.Product
    timestamps()
  end

  def changeset(cart_item, attrs) do
    cart_item
    |> cast(attrs, [:quantity, :user_id, :product_id])
    |> validate_required([:quantity, :user_id, :product_id])
    |> validate_number(:quantity, greater_than: 0)
    |> unique_constraint([:user_id, :product_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:product_id)
  end
end