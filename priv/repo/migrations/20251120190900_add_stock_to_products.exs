defmodule MiTiendaWeb.Repo.Migrations.AddStockToProducts do
  use Ecto.Migration

  def change do
    alter table(:products) do
      # Agregamos la columna stock, por defecto 0
      add :stock, :integer, default: 0, null: false
    end
  end
end