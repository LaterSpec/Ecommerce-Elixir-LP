defmodule MiTiendaWeb.Repo.Migrations.CreateStockItems do
  use Ecto.Migration

  def change do
    create table(:stock_items) do
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :quantity, :integer, null: false, default: 0
      timestamps()
    end

    create unique_index(:stock_items, [:product_id])
    create constraint(:stock_items, :quantity_must_be_nonnegative, check: "quantity >= 0")
  end
end
