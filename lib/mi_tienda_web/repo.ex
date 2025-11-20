defmodule MiTiendaWeb.Repo do
  use Ecto.Repo,
    otp_app: :mi_tienda_web,
    adapter: Ecto.Adapters.Postgres
end
