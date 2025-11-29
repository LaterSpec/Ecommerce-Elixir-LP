defmodule MiTiendaWebWeb.CartLive do
  use MiTiendaWebWeb, :live_view

  alias Supermarket.Cart

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, cart: %{items: [], total: 0}, username: "invitado", stock_conflicts: %{})}
  end
  
  @impl true
  def handle_params(params, _url, socket) do
    username = params["user_id"] || "invitado"
    
    case Cart.get_cart(username) do
      {:ok, cart} -> 
        {:noreply, assign(socket, cart: cart, username: username, stock_conflicts: %{})}
      _ -> 
        {:noreply, assign(socket, cart: %{items: [], total: 0}, username: username, stock_conflicts: %{})}
    end
  end

  # ELIMINAR ITEM
  @impl true
  def handle_event("delete_item", %{"sku" => sku_str}, socket) do
    sku = String.to_integer(sku_str)
    username = socket.assigns.username

    Cart.remove_from_cart(username, sku)

    {:ok, cart} = Cart.get_cart(username)
    
    conflicts = Map.delete(socket.assigns.stock_conflicts, sku)

    {:noreply, 
     socket
     |> put_flash(:info, "Producto eliminado.")
     |> assign(cart: cart, stock_conflicts: conflicts)}
  end

  # ACTUALIZAR CANTIDAD
  @impl true
  def handle_event("update_quantity", %{"sku" => sku_str, "quantity" => qty_str}, socket) do
    sku = String.to_integer(sku_str)
    quantity = String.to_integer(qty_str)
    username = socket.assigns.username

    case Cart.update_quantity(username, sku, quantity) do
      {:ok, _} ->
        {:ok, cart} = Cart.get_cart(username)
        conflicts = Map.delete(socket.assigns.stock_conflicts, sku)
        {:noreply, assign(socket, cart: cart, stock_conflicts: conflicts)}
      
      {:error, msg} when is_binary(msg) ->
        {:noreply, put_flash(socket, :error, msg)}
      
      _ ->
        {:ok, cart} = Cart.get_cart(username)
        {:noreply, assign(socket, cart: cart)}
    end
  end

  # === EVENTO PAGAR (CHECKOUT) ===
  @impl true
  def handle_event("checkout", _params, socket) do
    username = socket.assigns.username

    case Cart.checkout(username) do
      {:ok, result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Compra exitosa! Total pagado: $#{div(result.total_paid, 100)}.")
         |> push_navigate(to: "/productos?user_id=#{username}")}

      {:error, :stock_conflicts, conflicts} ->
        conflicts_map = Enum.reduce(conflicts, %{}, fn c, acc ->
          Map.put(acc, c.sku, c)
        end)
        
        {:ok, cart} = Cart.get_cart(username)
        
        {:noreply,
         socket
         |> put_flash(:error, "No se puede procesar tu compra. Algunos productos no tienen stock suficiente.")
         |> assign(cart: cart, stock_conflicts: conflicts_map)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error al pagar: #{reason}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- HEADER -->
      <header class="bg-white border-b border-gray-200 sticky top-0 z-50 shadow-sm">
        <div class="container mx-auto px-6 py-4">
          <div class="flex justify-between items-center">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 bg-black rounded-lg flex items-center justify-center">
                <span class="text-white font-bold text-xl">T</span>
              </div>
              <span class="text-xl font-bold text-gray-900 tracking-tight">TIENDA</span>
            </div>
            
            <div class="flex items-center gap-4">
              <.link 
                navigate={~p"/productos?user_id=#{@username}"} 
                class="bg-gray-900 text-white px-4 py-2 rounded-lg hover:bg-gray-800 transition-colors flex items-center gap-2 font-medium"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                </svg>
                <span class="hidden sm:inline">Volver a Tienda</span>
              </.link>
              
              <.link 
                navigate={~p"/login"} 
                class="bg-white text-gray-700 px-4 py-2 rounded-lg border border-gray-300 hover:bg-gray-100 transition-colors flex items-center gap-2 font-medium"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
                <span class="hidden sm:inline">Salir</span>
              </.link>
            </div>
          </div>
        </div>
      </header>

      <main class="container mx-auto px-6 py-8">
        <!-- TITULO -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-900 mb-1">Tu Carrito</h1>
          <p class="text-gray-500">Revisa tus productos antes de finalizar la compra</p>
        </div>

        <!-- ALERTAS -->
        <%= if msg = Phoenix.Flash.get(@flash, :info) do %>
          <div class="mb-6 bg-gray-100 border-l-4 border-gray-900 text-gray-800 px-4 py-3 rounded-r flex items-center gap-3">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            <%= msg %>
          </div>
        <% end %>
        <%= if msg = Phoenix.Flash.get(@flash, :error) do %>
          <div class="mb-6 bg-red-50 border-l-4 border-red-500 text-red-700 px-4 py-3 rounded-r flex items-center gap-3">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <%= msg %>
          </div>
        <% end %>

        <%= if @cart.items == [] do %>
          <!-- CARRITO VACIO -->
          <div class="text-center py-16 bg-white rounded-xl border border-gray-200">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-20 w-20 mx-auto text-gray-300 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
            <p class="text-gray-500 text-xl mb-2">Tu carrito esta vacio</p>
            <p class="text-gray-400 mb-6">Agrega algunos productos para comenzar</p>
            <a 
              href={"/productos?user_id=#{@username}"} 
              class="inline-flex items-center gap-2 bg-gray-900 text-white px-6 py-3 rounded-lg hover:bg-gray-800 transition-colors font-medium"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              Ir a la tienda
            </a>
          </div>
        <% else %>
          <div class="grid lg:grid-cols-3 gap-8">
            <!-- LISTA DE PRODUCTOS -->
            <div class="lg:col-span-2 space-y-4">
              <%= for item <- @cart.items do %>
                <% conflict = Map.get(@stock_conflicts, item.sku) %>
                <div class={"bg-white rounded-xl border p-5 #{if conflict, do: "border-red-300 bg-red-50", else: "border-gray-200"}"}>
                  <div class="flex gap-4">
                    <!-- Imagen placeholder -->
                    <div class="w-20 h-20 bg-gray-100 rounded-lg flex items-center justify-center flex-shrink-0">
                      <span class="text-2xl text-gray-400"><%= String.first(item.product_name) %></span>
                    </div>
                    
                    <!-- Info del producto -->
                    <div class="flex-1">
                      <div class="flex justify-between">
                        <div>
                          <h3 class="font-semibold text-gray-900"><%= item.product_name %></h3>
                          <p class="text-sm text-gray-500">SKU: <%= item.sku %></p>
                        </div>
                        <p class="font-bold text-gray-900">
                          $<%= div(item.subtotal, 100) %>
                        </p>
                      </div>
                      
                      <div class="flex items-center justify-between mt-3">
                        <div class="flex items-center gap-3">
                          <span class="text-sm text-gray-500">$<%= div(item.price, 100) %> c/u</span>
                          <div class="flex items-center gap-1 bg-gray-100 rounded-lg">
                            <button 
                              phx-click="update_quantity" 
                              phx-value-sku={item.sku}
                              phx-value-quantity={item.quantity - 1}
                              class="px-3 py-1 hover:bg-gray-200 rounded-l-lg transition-colors text-gray-600 font-medium"
                            >−</button>
                            <span class="px-3 font-semibold text-gray-900"><%= item.quantity %></span>
                            <button 
                              phx-click="update_quantity" 
                              phx-value-sku={item.sku}
                              phx-value-quantity={item.quantity + 1}
                              class="px-3 py-1 hover:bg-gray-200 rounded-r-lg transition-colors text-gray-600 font-medium"
                            >+</button>
                          </div>
                        </div>
                        
                        <button 
                          phx-click="delete_item" 
                          phx-value-sku={item.sku}
                          class="text-gray-400 hover:text-red-500 transition-colors"
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                        </button>
                      </div>
                      
                      <!-- Alerta de conflicto -->
                      <%= if conflict do %>
                        <div class="mt-3 p-3 bg-red-100 border border-red-200 rounded-lg">
                          <p class="text-red-700 text-sm font-medium flex items-center gap-2">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                            </svg>
                            <%= if conflict.available == 0 do %>
                              Sin stock disponible
                            <% else %>
                              Solo <%= conflict.available %> disponible(s)
                            <% end %>
                          </p>
                          <%= if conflict.available > 0 do %>
                            <button 
                              phx-click="update_quantity" 
                              phx-value-sku={item.sku}
                              phx-value-quantity={conflict.available}
                              class="mt-2 text-sm bg-gray-900 text-white px-3 py-1 rounded-lg hover:bg-gray-800 transition-colors"
                            >
                              Ajustar a <%= conflict.available %>
                            </button>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
            
            <!-- RESUMEN DE COMPRA -->
            <div class="lg:col-span-1">
              <div class="bg-white rounded-xl border border-gray-200 p-6 sticky top-24">
                <h2 class="text-lg font-bold text-gray-900 mb-4">Resumen</h2>
                
                <div class="space-y-3 mb-6">
                  <div class="flex justify-between text-gray-600">
                    <span>Productos (<%= length(@cart.items) %>)</span>
                    <span>$<%= div(@cart.total, 100) %></span>
                  </div>
                  <div class="flex justify-between text-gray-600">
                    <span>Envio</span>
                    <span class="text-green-600">Gratis</span>
                  </div>
                  <div class="border-t border-gray-200 pt-3">
                    <div class="flex justify-between text-xl font-bold text-gray-900">
                      <span>Total</span>
                      <span>$<%= div(@cart.total, 100) %></span>
                    </div>
                  </div>
                </div>
                
                <%= if map_size(@stock_conflicts) > 0 do %>
                  <div class="mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded-lg text-yellow-800 text-sm">
                    <p class="font-medium">Resuelve los conflictos de stock para continuar</p>
                  </div>
                <% end %>
                
                <button 
                  phx-click="checkout"
                  data-confirm="Confirmar compra?"
                  class={"w-full py-3 rounded-lg font-semibold transition-colors #{if map_size(@stock_conflicts) > 0, do: "bg-gray-200 text-gray-400 cursor-not-allowed", else: "bg-gray-900 text-white hover:bg-gray-800"}"}
                  disabled={map_size(@stock_conflicts) > 0}
                >
                  Finalizar Compra
                </button>
                
                <a 
                  href={"/productos?user_id=#{@username}"} 
                  class="block text-center mt-4 text-gray-600 hover:text-gray-900 text-sm font-medium"
                >
                  Seguir comprando
                </a>
              </div>
            </div>
          </div>
        <% end %>
      </main>
    </div>
    """
  end
end