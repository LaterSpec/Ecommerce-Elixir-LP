defmodule Supermarket.Repo.Migrations.CreateCartItems do
  use Ecto.Migration

  def change do
    create table(:cart_items) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :quantity, :integer, null: false, default: 1
      timestamps()
    end

    # Un usuario solo puede tener un ítem por producto en su carrito
    create unique_index(:cart_items, [:user_id, :product_id])
    create constraint(:cart_items, :quantity_must_be_positive, check: "quantity > 0")
  end
end