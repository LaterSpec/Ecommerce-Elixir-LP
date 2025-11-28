defmodule MiTiendaWebWeb.Router do
  use MiTiendaWebWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MiTiendaWebWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MiTiendaWebWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/productos", ProductLive, :index
    live "/carrito", CartLive, :index
    live "/register", RegisterLive, :index
    live "/login", LoginLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", MiTiendaWebWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:mi_tienda_web, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MiTiendaWebWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end