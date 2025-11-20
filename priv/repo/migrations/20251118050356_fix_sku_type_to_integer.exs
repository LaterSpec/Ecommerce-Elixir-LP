defmodule MiTiendaWeb.Repo.Migrations.FixSkuTypeToInteger do
  use Ecto.Migration

  def change do
    alter table(:products) do
      modify :sku, :integer, using: "sku::integer"
    end
  end
end