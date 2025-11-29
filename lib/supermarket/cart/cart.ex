defmodule Supermarket.Cart do
  import Ecto.Query, warn: false
  alias MiTiendaWeb.Repo
  alias Supermarket.Product
  alias Supermarket.Accounts.User
  alias Supermarket.Cart.CartItem

  # === 1. AGREGAR AL CARRITO ===
  def add_to_cart(username, sku, quantity \\ 1) do
    with {:ok, user} <- get_user_by_username(username),
         {:ok, product} <- get_product_by_sku(sku) do
      
      # Verificamos Stock Real disponible (Sumando los stock_items)
      total_stock = Enum.reduce(product.stock_items, 0, fn i, acc -> i.quantity + acc end)
      
      # Verificamos cuanto tiene ya este usuario en su carrito
      existing_item = Repo.get_by(CartItem, user_id: user.id, product_id: product.id)
      current_qty_in_cart = if existing_item, do: existing_item.quantity, else: 0

      if (current_qty_in_cart + quantity) <= total_stock do
        case existing_item do
          nil ->
            %CartItem{}
            |> CartItem.changeset(%{
              user_id: user.id,
              product_id: product.id,
              quantity: quantity
            })
            |> Repo.insert()
          
          item ->
            item
            |> CartItem.changeset(%{quantity: item.quantity + quantity})
            |> Repo.update()
        end
      else
        {:error, "Stock insuficiente. Solo quedan #{total_stock} disponibles."}
      end
    end
  end

  # === 2. VER CARRITO (SOLO DEL USUARIO) ===
  def get_cart(username) do
    case get_user_by_username(username) do
      {:ok, user} ->
        items = Repo.all(from c in CartItem,
          where: c.user_id == ^user.id,
          preload: [:product],
          order_by: [asc: c.inserted_at]
        )

        cart_items = Enum.map(items, fn item -> 
          %{
            sku: item.product.sku,
            product_name: item.product.name,
            price: item.product.price,
            quantity: item.quantity,
            subtotal: item.product.price * item.quantity
          }
        end)

        total = Enum.reduce(cart_items, 0, fn i, acc -> i.subtotal + acc end)
        {:ok, %{items: cart_items, total: total}}

      error -> error
    end
  end

  # === 3. ELIMINAR UN ITEM ===
  def remove_from_cart(username, sku) do
    with {:ok, user} <- get_user_by_username(username),
         {:ok, product} <- get_product_by_sku(sku) do
      
      case Repo.get_by(CartItem, user_id: user.id, product_id: product.id) do
        nil -> {:error, :not_in_cart}
        item -> Repo.delete(item)
      end
    end
  end

  # === 4. VACIAR CARRITO COMPLETO ===
  def clear_cart(username) do
    case get_user_by_username(username) do
      {:ok, user} ->
        from(c in CartItem, where: c.user_id == ^user.id)
        |> Repo.delete_all()
        {:ok, :cart_cleared}
      
      error -> error
    end
  end

  # === 5. VALIDAR STOCK ANTES DE CHECKOUT ===
  def validate_stock(username) do
    case get_cart(username) do
      {:ok, %{items: []}} ->
        {:error, :empty_cart}
      
      {:ok, %{items: items}} ->
        conflicts = Enum.reduce(items, [], fn item, acc ->
          product = Repo.get_by!(Product, sku: item.sku) |> Repo.preload(:stock_items)
          available_stock = Enum.reduce(product.stock_items, 0, fn i, sum -> i.quantity + sum end)
          
          if available_stock < item.quantity do
            [%{
              sku: item.sku,
              product_name: item.product_name,
              requested: item.quantity,
              available: available_stock
            } | acc]
          else
            acc
          end
        end)
        
        if conflicts == [] do
          {:ok, :valid}
        else
          {:error, :stock_conflicts, Enum.reverse(conflicts)}
        end
      
      error -> error
    end
  end

  # === 6. CHECKOUT (PAGAR Y DESCONTAR STOCK) ===
  def checkout(username) do
    case validate_stock(username) do
      {:error, :stock_conflicts, conflicts} ->
        {:error, :stock_conflicts, conflicts}
      
      {:error, :empty_cart} ->
        {:error, "El carrito esta vacio"}
      
      {:ok, :valid} ->
        Repo.transaction(fn ->
          case get_cart(username) do
            {:ok, %{items: items, total: total}} ->
              Enum.each(items, fn item ->
                product = Repo.get_by!(Product, sku: item.sku) |> Repo.preload(:stock_items)
                stock_record = List.first(product.stock_items)
                
                if stock_record && stock_record.quantity >= item.quantity do
                  stock_record
                  |> Ecto.Changeset.change(quantity: stock_record.quantity - item.quantity)
                  |> Repo.update!()
                else
                  Repo.rollback("No hay suficiente stock real para #{item.product_name}")
                end
              end)

              clear_cart(username)
              %{status: :success, total_paid: total, items_count: length(items)}
          end
        end)
    end
  end

  # === 7. ACTUALIZAR CANTIDAD EN CARRITO ===
  def update_quantity(username, sku, new_quantity) do
    with {:ok, user} <- get_user_by_username(username),
         {:ok, product} <- get_product_by_sku(sku) do
      
      case Repo.get_by(CartItem, user_id: user.id, product_id: product.id) do
        nil -> 
          {:error, :not_in_cart}
        item ->
          if new_quantity <= 0 do
            Repo.delete(item)
          else
            total_stock = Enum.reduce(product.stock_items, 0, fn i, acc -> i.quantity + acc end)
            
            if new_quantity <= total_stock do
              item
              |> CartItem.changeset(%{quantity: new_quantity})
              |> Repo.update()
            else
              {:error, "Solo hay #{total_stock} unidades disponibles"}
            end
          end
      end
    end
  end

  # === HELPERS PRIVADOS ===

  defp get_user_by_username(username) do
    case Repo.get_by(User, username: username) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  defp get_product_by_sku(sku) do
    # Preload stock_items es vital para verificar cantidades
    case Repo.get_by(Product, sku: sku) |> Repo.preload(:stock_items) do
      nil -> {:error, :product_not_found}
      product -> {:ok, product}
    end
  end
end