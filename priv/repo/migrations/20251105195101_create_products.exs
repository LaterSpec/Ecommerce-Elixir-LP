defmodule Supermarket.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :sku, :string
      add :category, :string
      add :price, :integer
      add :active, :boolean, default: true

      timestamps()
    end

    create unique_index(:products, [:sku])
  end
end
