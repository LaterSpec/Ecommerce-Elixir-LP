defmodule MiTiendaWebWeb.PageController do
  use MiTiendaWebWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
