defmodule Supermarket.Cart do
  import Ecto.Query
  alias Supermarket.Repo
  alias Supermarket.{Product}
  alias Supermarket.Accounts.User
  alias Supermarket.Cart.CartItem
  alias Supermarket.Inventory

  # Agregar producto al carrito (o incrementar cantidad)
  def add_to_cart(username, sku, quantity \\ 1) 
      when is_binary(username) and is_integer(sku) and quantity > 0 do
    
    with {:ok, user} <- get_user_by_username(username),
         {:ok, product} <- get_product_by_sku(sku),
         {:ok, _} <- check_stock(sku, quantity) do
      
      case Repo.get_by(CartItem, user_id: user.id, product_id: product.id) do
        nil ->
          # Crear nuevo ítem
          %CartItem{}
          |> CartItem.changeset(%{
            user_id: user.id,
            product_id: product.id,
            quantity: quantity
          })
          |> Repo.insert()
        
        cart_item ->
          # Incrementar cantidad existente
          new_qty = cart_item.quantity + quantity
          cart_item
          |> CartItem.changeset(%{quantity: new_qty})
          |> Repo.update()
      end
    end
  end

  # Ver carrito del usuario con detalles de productos
  def get_cart(username) when is_binary(username) do
    case get_user_by_username(username) do
      {:ok, user} ->
        items =
          from(ci in CartItem,
            join: p in Product, on: ci.product_id == p.id,
            where: ci.user_id == ^user.id,
            select: %{
              cart_item_id: ci.id,
              product_name: p.name,
              sku: p.sku,
              price: p.price,
              quantity: ci.quantity,
              subtotal: p.price * ci.quantity
            },
            order_by: [asc: ci.inserted_at]
          )
          |> Repo.all()

        total = Enum.reduce(items, 0, fn item, acc -> acc + item.subtotal end)
        {:ok, %{items: items, total: total}}
      
      error -> error
    end
  end

  # Actualizar cantidad de un producto en el carrito
  def update_quantity(username, sku, new_quantity) 
      when is_binary(username) and is_integer(sku) and new_quantity > 0 do
    
    with {:ok, user} <- get_user_by_username(username),
         {:ok, product} <- get_product_by_sku(sku),
         {:ok, _} <- check_stock(sku, new_quantity) do
      
      case Repo.get_by(CartItem, user_id: user.id, product_id: product.id) do
        nil -> {:error, :not_in_cart}
        cart_item ->
          cart_item
          |> CartItem.changeset(%{quantity: new_quantity})
          |> Repo.update()
      end
    end
  end

  # Eliminar producto del carrito
  def remove_from_cart(username, sku) when is_binary(username) and is_integer(sku) do
    with {:ok, user} <- get_user_by_username(username),
         {:ok, product} <- get_product_by_sku(sku) do
      
      case Repo.get_by(CartItem, user_id: user.id, product_id: product.id) do
        nil -> {:error, :not_in_cart}
        cart_item -> Repo.delete(cart_item)
      end
    end
  end

  # Vaciar carrito completo
  def clear_cart(username) when is_binary(username) do
    case get_user_by_username(username) do
      {:ok, user} ->
        {count, _} =
          from(ci in CartItem, where: ci.user_id == ^user.id)
          |> Repo.delete_all()
        
        {:ok, count}
      
      error -> error
    end
  end

  # Checkout (procesar compra y descontar stock)
  def checkout(username) when is_binary(username) do
    Repo.transaction(fn ->
      case get_cart(username) do
        {:ok, %{items: []}} ->
          Repo.rollback(:empty_cart)
        
        {:ok, %{items: items, total: total}} ->
          # Verificar y descontar stock
          Enum.each(items, fn item ->
            case Inventory.inc_stock_by_sku(item.sku, -item.quantity) do
              {:ok, _} -> :ok
              {:error, reason} -> Repo.rollback(reason)
            end
          end)
          
          # Limpiar carrito
          clear_cart(username)
          
          {:ok, %{items_count: length(items), total: total}}
        
        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  # === Helpers privados ===
  defp get_user_by_username(username) do
    case Repo.get_by(User, username: username) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  defp get_product_by_sku(sku) do
    case Repo.get_by(Product, sku: sku) do
      nil -> {:error, :product_not_found}
      product -> {:ok, product}
    end
  end

  defp check_stock(sku, requested_qty) do
    available = Inventory.get_stock_by_sku(sku)
    if available >= requested_qty do
      {:ok, available}
    else
      {:error, :insufficient_stock}
    end
  end
end