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
    
    categories = products
      |> Enum.map(& &1.category)
      |> Enum.uniq()
      |> Enum.sort()
    
    users_list = if current_user && current_user.role == "admin" do
      Repo.all(from u in User, order_by: [desc: u.inserted_at])
    else
      [] 
    end
    
    quantities = Enum.reduce(products, %{}, fn p, acc -> Map.put(acc, p.id, 1) end)
    
    socket = assign(socket, 
      products: products,
      filtered_products: products,
      current_user: current_user,
      users_list: users_list,
      product_form: @product_form_schema,
      categories: categories,
      search_text: "",
      selected_category: "all",
      quantities: quantities
    )
    {:ok, socket}
  end

  # === FILTRAR PRODUCTOS ===
  @impl true
  def handle_event("filter_products", %{"search" => search_text, "category" => category}, socket) do
    filtered = socket.assigns.products
      |> filter_by_category(category)
      |> filter_by_text(search_text)
    
    {:noreply, assign(socket, 
      filtered_products: filtered, 
      search_text: search_text, 
      selected_category: category
    )}
  end

  # === CAMBIAR CANTIDAD A AGREGAR ===
  @impl true
  def handle_event("change_quantity", %{"product_id" => product_id_str, "action" => action}, socket) do
    product_id = String.to_integer(product_id_str)
    quantities = socket.assigns.quantities
    current_qty = Map.get(quantities, product_id, 1)
    
    product = Enum.find(socket.assigns.products, & &1.id == product_id)
    max_stock = if product do
      Enum.reduce(product.stock_items || [], 0, fn i, acc -> i.quantity + acc end)
    else
      1
    end
    
    new_qty = case action do
      "increment" -> min(current_qty + 1, max_stock)
      "decrement" -> max(current_qty - 1, 1)
      _ -> current_qty
    end
    
    {:noreply, assign(socket, quantities: Map.put(quantities, product_id, new_qty))}
  end

  # === CREAR PRODUCTO ===
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
        new_product = %Product{} |> Product.changeset(product_params) |> Repo.insert!()
        
        %StockItem{}
        |> Ecto.Changeset.change(%{product_id: new_product.id, quantity: initial_stock})
        |> Repo.insert!()
        
        new_product
      end)

      case transaction_result do
        {:ok, _product} ->
          products = Repo.all(from p in Product, preload: [:stock_items], order_by: [asc: p.name])
          categories = products |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort()
          quantities = Enum.reduce(products, %{}, fn p, acc -> Map.put(acc, p.id, 1) end)
          
          filtered = products
            |> filter_by_category(socket.assigns.selected_category)
            |> filter_by_text(socket.assigns.search_text)
          
          {:noreply, 
           socket 
           |> put_flash(:info, "Producto creado.")
           |> assign(products: products, filtered_products: filtered, categories: categories, quantities: quantities, product_form: @product_form_schema)}
        
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Error. Revisa el SKU.")}
      end
    else
      {:noreply, put_flash(socket, :error, "No tienes permiso.")}
    end
  end

  # === NUEVO: ACTUALIZAR STOCK (+ / -) ===
  @impl true
  def handle_event("update_stock", %{"product_id" => id, "change" => change_str}, socket) do
    if socket.assigns.current_user.role == "admin" do
      change = String.to_integer(change_str)
      
      stock_item = Repo.one(from s in StockItem, where: s.product_id == ^id, limit: 1)

      if stock_item do
        new_quantity = stock_item.quantity + change
        
        if new_quantity >= 0 do
          stock_item
          |> Ecto.Changeset.change(quantity: new_quantity)
          |> Repo.update()
          
          products = Repo.all(from p in Product, preload: [:stock_items], order_by: [asc: p.name])
          filtered = products
            |> filter_by_category(socket.assigns.selected_category)
            |> filter_by_text(socket.assigns.search_text)
          
          {:noreply, assign(socket, products: products, filtered_products: filtered)}
        else
           {:noreply, put_flash(socket, :error, "El stock no puede ser negativo.")}
        end
      else
        {:noreply, put_flash(socket, :error, "No se encontro inventario para este producto.")}
      end
    else
      {:noreply, put_flash(socket, :error, "No tienes permiso.")}
    end
  end

  # === AGREGAR AL CARRITO ===
  @impl true
  def handle_event("add_to_cart", %{"sku" => sku, "quantity" => qty_str, "product_id" => product_id_str}, socket) do
    sku_int = String.to_integer(sku)
    quantity = String.to_integer(qty_str)
    product_id = String.to_integer(product_id_str)
    username = if socket.assigns.current_user, do: socket.assigns.current_user.username, else: "invitado"

    case Cart.add_to_cart(username, sku_int, quantity) do
      {:ok, _} -> 
        quantities = Map.put(socket.assigns.quantities, product_id, 1)
        {:noreply, 
         socket
         |> put_flash(:info, "#{quantity} unidad(es) agregada(s) al carrito")
         |> assign(quantities: quantities)}
      {:error, r} -> 
        {:noreply, put_flash(socket, :error, "Error: #{r}")}
    end
  end

  # === ELIMINAR PRODUCTO ===
  @impl true
  def handle_event("delete_product", %{"id" => id}, socket) do
    if socket.assigns.current_user.role == "admin" do
      product = Repo.get!(Product, id)
      Repo.delete(product)
      products = Repo.all(from p in Product, preload: [:stock_items], order_by: [asc: p.name])
      categories = products |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort()
      quantities = Enum.reduce(products, %{}, fn p, acc -> Map.put(acc, p.id, 1) end)
      
      filtered = products
        |> filter_by_category(socket.assigns.selected_category)
        |> filter_by_text(socket.assigns.search_text)
      
      {:noreply, assign(socket, products: products, filtered_products: filtered, categories: categories, quantities: quantities)}
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

  # === HELPERS DE FILTRADO ===
  defp filter_by_category(products, "all"), do: products
  defp filter_by_category(products, category) do
    Enum.filter(products, fn p -> p.category == category end)
  end

  defp filter_by_text(products, ""), do: products
  defp filter_by_text(products, text) do
    search_lower = String.downcase(text)
    Enum.filter(products, fn p -> 
      String.contains?(String.downcase(p.name), search_lower)
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- HEADER -->
      <header class="bg-white border-b border-gray-200 sticky top-0 z-50 shadow-sm">
        <div class="container mx-auto px-6 py-4">
          <div class="flex justify-between items-center">
            <!-- Logo / Titulo -->
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 bg-black rounded-lg flex items-center justify-center">
                <span class="text-white font-bold text-xl">T</span>
              </div>
              <span class="text-xl font-bold text-gray-900 tracking-tight">TIENDA</span>
            </div>
            
            <!-- Usuario y Acciones -->
            <div class="flex items-center gap-4">
              <%= if @current_user do %>
                <div class="text-right hidden md:block">
                  <p class="text-sm text-gray-500">Sesion activa</p>
                  <p class="font-semibold text-gray-900 flex items-center gap-2">
                    <%= @current_user.username %>
                    <%= if @current_user.role == "admin" do %>
                      <span class="bg-black text-white text-xs px-2 py-0.5 rounded uppercase tracking-wider">Admin</span>
                    <% end %>
                  </p>
                </div>
              <% end %>
              
              <%= if !@current_user or @current_user.role != "admin" do %>
                <.link 
                  navigate={~p"/carrito?user_id=#{@current_user && @current_user.username}"} 
                  class="bg-gray-900 text-white px-4 py-2 rounded-lg hover:bg-gray-800 transition-colors flex items-center gap-2 font-medium"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                  <span class="hidden sm:inline">Carrito</span>
                </.link>
              <% end %>
              
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
        <!-- SALUDO DE BIENVENIDA -->
        <div class="mb-8">
          <%= if @current_user && @current_user.role == "admin" do %>
            <h1 class="text-3xl font-bold text-gray-900 mb-1">Panel de Administracion</h1>
            <p class="text-gray-500">Gestiona productos, inventario y usuarios</p>
          <% else %>
            <h1 class="text-3xl font-bold text-gray-900 mb-1">
              Bienvenido, <span class="text-gray-700"><%= if @current_user, do: @current_user.username, else: "Invitado" %></span>
            </h1>
            <p class="text-gray-500 text-lg">Que bueno volverte a ver</p>
            <h2 class="text-xl font-semibold text-gray-800 mt-4">Nuestro Catalogo</h2>
          <% end %>
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

        <!-- FORMULARIO ADMIN PARA CREAR PRODUCTO -->
        <%= if @current_user && @current_user.role == "admin" do %>
          <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm mb-8">
            <h2 class="text-lg font-bold mb-4 text-gray-900 flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
              Agregar Nuevo Producto
            </h2>
            <.form for={@product_form} phx-submit="create_product" as={:product} class="grid grid-cols-1 md:grid-cols-6 gap-4 items-end">
              <div>
                <label class="block text-gray-600 text-sm font-medium mb-1">Nombre</label>
                <input type="text" name="product[name]" required placeholder="Ej. Arroz" class="w-full p-2.5 border border-gray-300 rounded-lg text-gray-900 focus:ring-2 focus:ring-gray-900 focus:border-gray-900" />
              </div>
              <div>
                <label class="block text-gray-600 text-sm font-medium mb-1">SKU</label>
                <input type="number" name="product[sku]" required placeholder="Ej. 5001" class="w-full p-2.5 border border-gray-300 rounded-lg text-gray-900 focus:ring-2 focus:ring-gray-900 focus:border-gray-900" />
              </div>
              <div>
                <label class="block text-gray-600 text-sm font-medium mb-1">Categoria</label>
                <input type="text" name="product[category]" required placeholder="Ej. Granos" class="w-full p-2.5 border border-gray-300 rounded-lg text-gray-900 focus:ring-2 focus:ring-gray-900 focus:border-gray-900" />
              </div>
              <div>
                <label class="block text-gray-600 text-sm font-medium mb-1">Precio (Ctvs)</label>
                <input type="number" name="product[price]" required placeholder="1000 = $10" class="w-full p-2.5 border border-gray-300 rounded-lg text-gray-900 focus:ring-2 focus:ring-gray-900 focus:border-gray-900" />
              </div>
              <div>
                <label class="block text-gray-600 text-sm font-medium mb-1">Stock</label>
                <input type="number" name="product[stock]" required placeholder="Ej. 50" class="w-full p-2.5 border border-gray-300 rounded-lg text-gray-900 focus:ring-2 focus:ring-gray-900 focus:border-gray-900" />
              </div>
              <div>
                <button type="submit" class="w-full bg-gray-900 text-white font-semibold py-2.5 px-4 rounded-lg hover:bg-gray-800 transition-colors">
                  Crear Producto
                </button>
              </div>
            </.form>
          </div>
        <% end %>

        <!-- BARRA DE BUSQUEDA Y FILTROS -->
        <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm mb-8">
          <form phx-submit="filter_products" class="flex flex-col md:flex-row gap-4 items-end">
            <div class="flex-1">
              <label class="block text-gray-600 text-sm font-medium mb-2">Buscar producto</label>
              <div class="relative">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                <input 
                  type="text" 
                  name="search" 
                  value={@search_text}
                  placeholder="Escribe el nombre del producto..."
                  class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg text-gray-900 focus:ring-2 focus:ring-gray-900 focus:border-gray-900"
                />
              </div>
            </div>
            <div class="md:w-56">
              <label class="block text-gray-600 text-sm font-medium mb-2">Categoria</label>
              <select 
                name="category" 
                class="w-full py-3 px-4 border border-gray-300 rounded-lg text-gray-900 focus:ring-2 focus:ring-gray-900 focus:border-gray-900 bg-white"
              >
                <option value="all" selected={@selected_category == "all"}>Todas las categorias</option>
                <%= for cat <- @categories do %>
                  <option value={cat} selected={@selected_category == cat}><%= cat %></option>
                <% end %>
              </select>
            </div>
            <div>
              <button 
                type="submit" 
                class="bg-gray-900 text-white font-semibold py-3 px-8 rounded-lg hover:bg-gray-800 transition-colors"
              >
                Buscar
              </button>
            </div>
          </form>
          
          <%= if @search_text != "" or @selected_category != "all" do %>
            <div class="mt-4 pt-4 border-t border-gray-100 flex flex-wrap items-center gap-2 text-sm">
              <span class="text-gray-500">Filtros:</span>
              <%= if @search_text != "" do %>
                <span class="bg-gray-100 text-gray-700 px-3 py-1 rounded-full">"<%= @search_text %>"</span>
              <% end %>
              <%= if @selected_category != "all" do %>
                <span class="bg-gray-900 text-white px-3 py-1 rounded-full"><%= @selected_category %></span>
              <% end %>
              <span class="text-gray-400 ml-2"><%= length(@filtered_products) %> resultados</span>
            </div>
          <% end %>
        </div>

        <!-- GRID DE PRODUCTOS -->
        <%= if @filtered_products == [] do %>
          <div class="text-center py-16 bg-white rounded-xl border border-gray-200">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto text-gray-300 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
            </svg>
            <p class="text-gray-500 text-lg">No se encontraron productos</p>
            <p class="text-gray-400 text-sm mt-1">Intenta con otros filtros de busqueda</p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 mb-12">
            <div :for={product <- @filtered_products} class="bg-white rounded-xl border border-gray-200 overflow-hidden hover:shadow-lg transition-shadow group">
              <!-- Imagen placeholder -->
              <div class="h-40 bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center">
                <span class="text-4xl text-gray-400 group-hover:scale-110 transition-transform">
                  <%= String.first(product.name) %>
                </span>
              </div>
              
              <div class="p-4">
                <div class="flex justify-between items-start mb-2">
                  <div>
                    <h3 class="font-semibold text-gray-900 text-lg"><%= product.name %></h3>
                    <p class="text-gray-500 text-sm"><%= product.category %></p>
                  </div>
                  <p class="text-xl font-bold text-gray-900">
                    $<%= div(product.price, 100) %>
                  </p>
                </div>
                
                <div class="flex justify-between items-center text-sm text-gray-400 mb-4">
                  <span>SKU: <%= product.sku %></span>
                  <% stock = Enum.reduce(product.stock_items || [], 0, fn i, acc -> i.quantity + acc end) %>
                  
                  <%= if @current_user && @current_user.role == "admin" do %>
                    <div class="flex items-center gap-1 bg-gray-100 rounded-lg">
                      <button 
                        phx-click="update_stock" 
                        phx-value-product_id={product.id} 
                        phx-value-change="-1"
                        class="px-2 py-1 hover:bg-gray-200 rounded-l-lg transition-colors text-gray-600"
                      >−</button>
                      <span class={"px-2 font-medium #{if stock == 0, do: "text-red-500", else: "text-gray-700"}"}><%= stock %></span>
                      <button 
                        phx-click="update_stock" 
                        phx-value-product_id={product.id} 
                        phx-value-change="1"
                        class="px-2 py-1 hover:bg-gray-200 rounded-r-lg transition-colors text-gray-600"
                      >+</button>
                    </div>
                  <% else %>
                    <span class={"font-medium #{if stock == 0, do: "text-red-500", else: "text-gray-600"}"}>
                      <%= if stock == 0, do: "Agotado", else: "#{stock} disponibles" %>
                    </span>
                  <% end %>
                </div>

                <%= if @current_user && @current_user.role == "admin" do %>
                  <button 
                    phx-click="delete_product" 
                    phx-value-id={product.id}
                    data-confirm="Eliminar producto?"
                    class="w-full py-2.5 border border-red-200 text-red-600 font-medium rounded-lg hover:bg-red-50 transition-colors"
                  >
                    Eliminar
                  </button>
                <% else %>
                  <% stock = Enum.reduce(product.stock_items || [], 0, fn i, acc -> i.quantity + acc end) %>
                  <% qty = Map.get(@quantities, product.id, 1) %>
                  
                  <%= if stock > 0 do %>
                    <div class="space-y-3">
                      <div class="flex items-center justify-center gap-4 bg-gray-50 py-2 rounded-lg">
                        <button 
                          phx-click="change_quantity" 
                          phx-value-product_id={product.id}
                          phx-value-action="decrement"
                          class={"w-8 h-8 rounded-full flex items-center justify-center font-bold transition-colors #{if qty <= 1, do: "bg-gray-200 text-gray-400 cursor-not-allowed", else: "bg-gray-300 hover:bg-gray-400 text-gray-700"}"}
                          disabled={qty <= 1}
                        >−</button>
                        <span class="text-xl font-bold text-gray-900 w-8 text-center"><%= qty %></span>
                        <button 
                          phx-click="change_quantity" 
                          phx-value-product_id={product.id}
                          phx-value-action="increment"
                          class={"w-8 h-8 rounded-full flex items-center justify-center font-bold transition-colors #{if qty >= stock, do: "bg-gray-200 text-gray-400 cursor-not-allowed", else: "bg-gray-300 hover:bg-gray-400 text-gray-700"}"}
                          disabled={qty >= stock}
                        >+</button>
                      </div>
                      
                      <button 
                        phx-click="add_to_cart" 
                        phx-value-sku={to_string(product.sku)}
                        phx-value-quantity={to_string(qty)}
                        phx-value-product_id={to_string(product.id)}
                        class="w-full bg-gray-900 text-white font-semibold py-2.5 rounded-lg hover:bg-gray-800 transition-colors"
                      >
                        Agregar <%= qty %> al carrito
                      </button>
                    </div>
                  <% else %>
                    <button 
                      disabled
                      class="w-full py-2.5 bg-gray-100 text-gray-400 font-medium rounded-lg cursor-not-allowed"
                    >
                      Sin stock
                    </button>
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>

        <!-- SECCION ADMIN: GESTION DE USUARIOS -->
        <%= if @current_user && @current_user.role == "admin" do %>
          <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
            <h2 class="text-lg font-bold mb-4 text-gray-900 flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
              Gestion de Usuarios
            </h2>
            <div class="divide-y divide-gray-100">
              <%= for user <- @users_list do %>
                <div class="py-4 flex items-center justify-between">
                  <div class="flex items-center gap-3">
                    <div class="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
                      <span class="font-semibold text-gray-600"><%= String.first(user.username) |> String.upcase() %></span>
                    </div>
                    <div>
                      <p class="font-medium text-gray-900"><%= user.username %></p>
                      <p class="text-sm text-gray-500">
                        <%= if user.role == "admin", do: "Administrador", else: "Cliente" %> · ID: <%= user.id %>
                      </p>
                    </div>
                  </div>
                  <%= if user.id != @current_user.id do %>
                    <button 
                      phx-click="delete_user" 
                      phx-value-id={user.id}
                      data-confirm={"Expulsar a #{user.username}?"}
                      class="text-red-600 hover:text-red-700 text-sm font-medium hover:underline"
                    >
                      Expulsar
                    </button>
                  <% else %>
                    <span class="text-sm text-gray-400 italic">Tu cuenta</span>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </main>
    </div>
    """
  end
end