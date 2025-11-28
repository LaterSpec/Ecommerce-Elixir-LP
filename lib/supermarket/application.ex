defmodule Supermarket.Application do
  use Application

  def start(_type, _args) do
    children = [
      MiTiendaWeb.Repo
    ]

    opts = [strategy: :one_for_one, name: Supermarket.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
