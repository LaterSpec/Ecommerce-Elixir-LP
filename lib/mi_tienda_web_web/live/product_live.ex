defmodule MiTiendaWebWeb.ProductLive do
  use MiTiendaWebWeb, :live_view

  alias MiTiendaWeb.Repo
  alias Supermarket.Product
  alias Supermarket.Cart
  
  @impl true
  def mount(params, _session, socket) do
    # === AQUI RECIBIMOS EL ID DE LA URL ===
    current_user_id = params["user_id"] || "invitado"

    products = Repo.all(Product)
    
    socket = assign(socket, 
      products: products, 
      current_user_id: current_user_id
    )
    {:ok, socket}
  end

  @impl true
  def handle_event("add_to_cart", %{"sku" => sku}, socket) do
    sku_int = String.to_integer(sku)
    # Usamos el ID que leimos de la URL
    username = socket.assigns.current_user_id

    case Cart.add_to_cart(username, sku_int, 1) do
      {:ok, _cart_item} ->
        {:noreply, put_flash(socket, :info, "Producto anadido al carrito")}
        
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error: #{reason}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold">Nuestro Catalogo</h1>
        
        <div class="text-right">
          <p class="text-gray-600 text-sm">Usuario: <%= @current_user_id %></p>
          <.link navigate={~p"/carrito"} class="bg-orange-500 text-white px-4 py-2 rounded hover:bg-orange-600">
            Ver Carrito
          </.link>
        </div>
      </div>
      
      <%= if msg = Phoenix.Flash.get(@flash, :info) do %>
        <div class="mb-4 bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative">
          <%= msg %>
        </div>
      <% end %>

      <%= if msg = Phoenix.Flash.get(@flash, :error) do %>
        <div class="mb-4 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative">
          <%= msg %>
        </div>
      <% end %>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div :for={product <- @products} class="border rounded-lg shadow-lg p-4 bg-white flex flex-col justify-between">
          <div>
            <h2 class="text-xl font-semibold text-gray-800"><%= product.name %></h2>
            <p class="text-gray-600"><%= product.category %></p>
            <p class="text-lg font-bold text-blue-600 mt-2">
              $<%= div(product.price, 100) %>.<%= rem(product.price, 100) |> Integer.to_string() |> String.pad_leading(2, "0") %>
            </p>
            <p class="text-sm text-gray-500 mt-2">SKU: <%= product.sku %></p>
          </div>

          <button 
            phx-click="add_to_cart" 
            phx-value-sku={to_string(product.sku)}
            class="mt-4 w-full bg-blue-600 text-white font-bold py-2 px-4 rounded hover:bg-blue-700"
          >
            Anadir al Carrito
          </button>
        </div>
      </div>
    </div>
    """
  end
end