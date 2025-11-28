defmodule MiTiendaWebWeb.ProductLive do
  use MiTiendaWebWeb, :live_view

  alias MiTiendaWeb.Repo
  alias Supermarket.Product
  alias Supermarket.Cart
  alias Supermarket.Accounts.User
  alias Supermarket.Inventory.StockItem
  import Ecto.Query

  @product_form_schema %{"name" => "", "sku" => "", "category" => "", "price" => "", "stock" => ""}

  @impl true
  def mount(params, _session, socket) do
    username_from_url = params["user_id"]

    current_user = if username_from_url do
      Repo.get_by(User, username: username_from_url)
    else
      nil
    end

    products = Repo.all(from p in Product, preload: [:stock_items], order_by: [asc: p.name])
    
    users_list = if current_user && current_user.role == "admin" do
      Repo.all(from u in User, order_by: [desc: u.inserted_at])
    else
      [] 
    end
    
    socket = assign(socket, 
      products: products, 
      current_user: current_user,
      users_list: users_list,
      product_form: @product_form_schema
    )
    {:ok, socket}
  end

  # === CREAR PRODUCTO (CORREGIDO: SIN CAMPO STATE) ===
  @impl true
  def handle_event("create_product", %{"product" => params}, socket) do
    if socket.assigns.current_user.role == "admin" do
      product_params = %{
        name: params["name"],
        category: params["category"],
        sku: String.to_integer(params["sku"]),
        price: String.to_integer(params["price"])
      }
      initial_stock = String.to_integer(params["stock"])

      transaction_result = Repo.transaction(fn ->
        # 1. Crear Producto
        new_product = %Product{}
        |> Product.changeset(product_params)
        |> Repo.insert!()

        # 2. Crear StockItem (SIN EL CAMPO :state)
        %StockItem{}
        |> Ecto.Changeset.change(%{
          product_id: new_product.id,
          quantity: initial_stock
          # state: "available"  <--- ESTO ES LO QUE DABABA ERROR, LO QUITAMOS
        })
        |> Repo.insert!()
        
        new_product
      end)

      case transaction_result do
        {:ok, _product} ->
          products = Repo.all(from p in Product, preload: [:stock_items], order_by: [asc: p.name])
          
          {:noreply, 
           socket 
           |> put_flash(:info, "Producto y Stock creados exitosamente.")
           |> assign(products: products, product_form: @product_form_schema)}
        
        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Error al crear. Revisa que el SKU no este repetido.")}
      end
    else
      {:noreply, put_flash(socket, :error, "No tienes permiso.")}
    end
  end

  # === EVENTO: USUARIO AGREGA AL CARRITO ===
  @impl true
  def handle_event("add_to_cart", %{"sku" => sku}, socket) do
    sku_int = String.to_integer(sku)
    username = if socket.assigns.current_user, do: socket.assigns.current_user.username, else: "invitado"

    case Cart.add_to_cart(username, sku_int, 1) do
      {:ok, _cart_item} ->
        {:noreply, put_flash(socket, :info, "Producto agregado al carrito")}
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error: #{reason}")}
    end
  end

  # === ELIMINAR PRODUCTO ===
  @impl true
  def handle_event("delete_product", %{"id" => id}, socket) do
    if socket.assigns.current_user.role == "admin" do
      product = Repo.get!(Product, id)
      Repo.delete(product)
      products = Repo.all(from p in Product, preload: [:stock_items], order_by: [asc: p.name])
      {:noreply, assign(socket, products: products)}
    else
      {:noreply, put_flash(socket, :error, "No tienes permiso.")}
    end
  end

  # === ELIMINAR USUARIO ===
  @impl true
  def handle_event("delete_user", %{"id" => id}, socket) do
    if socket.assigns.current_user.role == "admin" do
      if String.to_integer(id) == socket.assigns.current_user.id do
        {:noreply, put_flash(socket, :error, "No puedes eliminar tu propia cuenta.")}
      else
        Repo.delete(Repo.get!(User, id))
        users = Repo.all(from u in User, order_by: [desc: u.inserted_at])
        {:noreply, assign(socket, users_list: users)} 
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-8">
      
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold">
          <%= if @current_user && @current_user.role == "admin" do %>
            PANEL DE ADMINISTRACION
          <% else %>
            Nuestro Catalogo
          <% end %>
        </h1>
        
        <div class="text-right flex items-center gap-4">
          <div>
            <%= if @current_user do %>
              <p class="text-gray-800 font-bold flex items-center">
                Hola, <%= @current_user.username %>
                <%= if @current_user.role == "admin" do %>
                  <span class="bg-red-600 text-white text-xs px-2 py-1 rounded ml-2 uppercase font-bold tracking-wider">
                    ADMIN
                  </span>
                <% end %>
              </p>
            <% else %>
              <p class="text-gray-600">Invitado</p>
            <% end %>
          </div>

          <%= if !@current_user or @current_user.role != "admin" do %>
            <.link navigate={~p"/carrito?user_id=#{@current_user && @current_user.username}"} class="bg-orange-500 text-white px-4 py-2 rounded hover:bg-orange-600 flex items-center font-bold">
              Ver Carrito
            </.link>
          <% end %>
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

      <%= if @current_user && @current_user.role == "admin" do %>
        <div class="bg-gray-100 p-6 rounded-lg border border-gray-300 mb-8">
          <h2 class="text-xl font-bold mb-4 text-gray-800">Agregar Nuevo Producto</h2>
          <.form for={@product_form} phx-submit="create_product" as={:product} class="grid grid-cols-1 md:grid-cols-6 gap-4 items-end">
            
            <div>
              <label class="block text-gray-900 text-sm font-bold mb-1">Nombre</label>
              <input type="text" name="product[name]" required placeholder="Ej. Arroz" class="w-full p-2 border rounded text-gray-900" />
            </div>
            <div>
              <label class="block text-gray-900 text-sm font-bold mb-1">SKU</label>
              <input type="number" name="product[sku]" required placeholder="Ej. 5001" class="w-full p-2 border rounded text-gray-900" />
            </div>
            <div>
              <label class="block text-gray-900 text-sm font-bold mb-1">Categoria</label>
              <input type="text" name="product[category]" required placeholder="Ej. Granos" class="w-full p-2 border rounded text-gray-900" />
            </div>
            <div>
              <label class="block text-gray-900 text-sm font-bold mb-1">Precio (Ctvs)</label>
              <input type="number" name="product[price]" required placeholder="1000 = $10.00" class="w-full p-2 border rounded text-gray-900" />
            </div>
            <div>
              <label class="block text-gray-900 text-sm font-bold mb-1">Stock Inicial</label>
              <input type="number" name="product[stock]" required placeholder="Ej. 50" class="w-full p-2 border rounded text-gray-900" />
            </div>

            <div>
              <button type="submit" class="w-full bg-green-600 text-white font-bold py-2 px-4 rounded hover:bg-green-700">
                + CREAR
              </button>
            </div>
          </.form>
        </div>
      <% end %>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
        <div :for={product <- @products} class="border rounded-lg shadow-lg p-4 bg-white flex flex-col justify-between">
          <div>
            <h2 class="text-xl font-semibold text-gray-800"><%= product.name %></h2>
            <p class="text-gray-600"><%= product.category %></p>
            <p class="text-lg font-bold text-blue-600 mt-2">
              $<%= div(product.price, 100) %>.<%= rem(product.price, 100) |> Integer.to_string() |> String.pad_leading(2, "0") %>
            </p>
            
            <div class="flex justify-between text-sm text-gray-500 mt-2">
              <span>SKU: <%= product.sku %></span>
              <span class="font-bold text-gray-700">
                Stock: <%= Enum.reduce(product.stock_items || [], 0, fn i, acc -> i.quantity + acc end) %>
              </span>
            </div>
          </div>

          <%= if @current_user && @current_user.role == "admin" do %>
            <button 
              phx-click="delete_product" 
              phx-value-id={product.id}
              data-confirm="Seguro que quieres eliminar este producto?"
              class="mt-4 w-full bg-red-600 text-white font-bold py-2 px-4 rounded hover:bg-red-700"
            >
              ELIMINAR
            </button>
          <% else %>
            <button 
              phx-click="add_to_cart" 
              phx-value-sku={to_string(product.sku)}
              class="mt-4 w-full bg-blue-600 text-white font-bold py-2 px-4 rounded hover:bg-blue-700"
            >
              Agregar al Carrito
            </button>
          <% end %>
        </div>
      </div>

      <%= if @current_user && @current_user.role == "admin" do %>
        <div class="bg-gray-100 p-6 rounded-lg border border-gray-300">
          <h2 class="text-2xl font-bold mb-4 text-gray-800">Gestion de Usuarios</h2>
          <div class="bg-white shadow overflow-hidden rounded-md">
            <ul class="divide-y divide-gray-200">
              <%= for user <- @users_list do %>
                <li class="px-6 py-4 flex items-center justify-between">
                  <div>
                    <p class="text-lg font-medium text-gray-900"><%= user.username %></p>
                    <p class="text-sm text-gray-500">Rol: <%= user.role %> | ID: <%= user.id %></p>
                  </div>
                  <%= if user.id != @current_user.id do %>
                    <button 
                      phx-click="delete_user" 
                      phx-value-id={user.id}
                      data-confirm={"Expulsar a #{user.username}?"}
                      class="bg-red-100 text-red-700 px-3 py-1 rounded border border-red-300 hover:bg-red-200 font-bold text-sm"
                    >
                      Expulsar Usuario
                    </button>
                  <% else %>
                    <span class="text-green-600 font-bold text-sm px-3 py-1 bg-green-100 rounded">Tu Usuario</span>
                  <% end %>
                </li>
              <% end %>
            </ul>
          </div>
        </div>
      <% end %>

    </div>
    """
  end
end