defmodule MiTiendaWeb.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Por defecto, todos seran "user" (clientes normales)
      add :role, :string, default: "user", null: false
    end
  end
end