defmodule MiTiendaWebWeb.CartLive do
  use MiTiendaWebWeb, :live_view

  alias Supermarket.Cart

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, cart: %{items: [], total: 0}, username: "invitado")}
  end
  
  @impl true
  def handle_params(params, _url, socket) do
    username = params["user_id"] || "invitado"
    
    case Cart.get_cart(username) do
      {:ok, cart} -> 
        {:noreply, assign(socket, cart: cart, username: username)}
      _ -> 
        {:noreply, assign(socket, cart: %{items: [], total: 0}, username: username)}
    end
  end

  # ELIMINAR ITEM
  @impl true
  def handle_event("delete_item", %{"sku" => sku_str}, socket) do
    sku = String.to_integer(sku_str)
    username = socket.assigns.username

    Cart.remove_from_cart(username, sku)

    {:ok, cart} = Cart.get_cart(username)

    {:noreply, 
     socket
     |> put_flash(:info, "Producto eliminado.")
     |> assign(cart: cart)}
  end

  # === EVENTO PAGAR (CHECKOUT) ===
  @impl true
  def handle_event("checkout", _params, socket) do
    username = socket.assigns.username

    case Cart.checkout(username) do
      {:ok, result} ->
        {:noreply,
         socket
         # Eliminado el signo de exclamacion invertido para evitar error
         |> put_flash(:info, "Compra exitosa! Total pagado: $#{div(result.total_paid, 100)}.")
         |> push_navigate(to: "/productos?user_id=#{username}")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error al pagar: #{reason}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-8">
      <h1 class="text-3xl font-bold mb-6">Tu Carrito de Compras</h1>

      <%= if @cart.items == [] do %>
        <div class="text-gray-500 text-xl">Tu carrito esta vacio.</div>
        <a href={"/productos?user_id=#{@username}"} class="text-blue-600 underline mt-4 block">Volver a la tienda</a>
      <% else %>
        
        <div class="bg-white shadow-md rounded-lg overflow-hidden">
          <table class="min-w-full leading-normal">
            <thead>
              <tr>
                <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Producto</th>
                <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Precio</th>
                <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Cant.</th>
                <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Subtotal</th>
                <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100"></th>
              </tr>
            </thead>
            <tbody>
              <%= for item <- @cart.items do %>
                <tr>
                  <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm">
                    <p class="text-gray-900 whitespace-no-wrap font-bold"><%= item.product_name %></p>
                    <p class="text-gray-500 text-xs">SKU: <%= item.sku %></p>
                  </td>
                  
                  <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm text-gray-900 font-medium">
                    $<%= div(item.price, 100) %>.<%= rem(item.price, 100) |> Integer.to_string() |> String.pad_leading(2, "0") %>
                  </td>

                  <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm text-gray-900 font-medium">
                    <%= item.quantity %>
                  </td>

                  <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm font-bold text-blue-600">
                    $<%= div(item.subtotal, 100) %>.<%= rem(item.subtotal, 100) |> Integer.to_string() |> String.pad_leading(2, "0") %>
                  </td>

                  <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm text-right">
                    <button 
                      phx-click="delete_item" 
                      phx-value-sku={item.sku}
                      class="text-red-600 hover:text-red-900 font-bold"
                    >
                      Eliminar
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
          
          <div class="px-5 py-5 bg-gray-100 text-right">
            <h3 class="text-xl font-bold text-gray-800">
              Total: $<%= div(@cart.total, 100) %>.<%= rem(@cart.total, 100) |> Integer.to_string() |> String.pad_leading(2, "0") %>
            </h3>
          </div>
        </div>

        <div class="mt-6 flex justify-end space-x-4">
            <a href={"/productos?user_id=#{@username}"} class="bg-gray-500 text-white font-bold py-2 px-4 rounded hover:bg-gray-600">Seguir Comprando</a>
            
            <button 
              phx-click="checkout"
              data-confirm="Confirmar compra?"
              class="bg-green-600 text-white font-bold py-2 px-4 rounded hover:bg-green-700"
            >
              Pagar (Checkout)
            </button>
        </div>

      <% end %>
    </div>
    """
  end
end