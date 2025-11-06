# Ejecutar con: elixir lib/cart_test.exs

Mix.install([{:ecto_sql, "~> 3.10"}, {:postgrex, ">= 0.0.0"}])

defmodule Supermarket.Repo do
  use Ecto.Repo, otp_app: :supermarket, adapter: Ecto.Adapters.Postgres
end

Application.put_env(:supermarket, Supermarket.Repo,
  username: "postgres",
  password: "12345",
  hostname: "localhost",
  database: "supermarket_dev",
  port: 5432,
  pool_size: 5
)

defmodule Supermarket.Product do
  use Ecto.Schema
  schema "products" do
    field :name, :string
    field :sku, :integer
    field :category, :string
    field :price, :integer
    field :active, :boolean, default: true
    timestamps()
  end
end

defmodule Supermarket.Accounts.User do
  use Ecto.Schema
  schema "users" do
    field :username, :string
    field :password_hash, :string
    timestamps()
  end
end

defmodule Supermarket.Inventory.StockItem do
  use Ecto.Schema
  schema "stock_items" do
    field :quantity, :integer, default: 0
    belongs_to :product, Supermarket.Product
    timestamps()
  end
end

defmodule Supermarket.Cart.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cart_items" do
    field :quantity, :integer, default: 1
    belongs_to :user, Supermarket.Accounts.User
    belongs_to :product, Supermarket.Product
    timestamps()
  end

  def changeset(cart_item, attrs) do
    cart_item
    |> cast(attrs, [:quantity, :user_id, :product_id])
    |> validate_required([:quantity, :user_id, :product_id])
    |> validate_number(:quantity, greater_than: 0)
    |> unique_constraint([:user_id, :product_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:product_id)
  end
end

defmodule Supermarket.Inventory do
  import Ecto.Query
  alias Supermarket.Repo
  alias Supermarket.Product
  alias Supermarket.Inventory.StockItem

  def get_stock_by_sku(sku) when is_integer(sku) do
    from(si in StockItem,
      join: p in Product, on: p.id == si.product_id,
      where: p.sku == ^sku,
      select: si.quantity
    )
    |> Repo.one()
    |> case do
      nil -> 0
      q   -> q
    end
  end

  def inc_stock_by_sku(sku, delta) when is_integer(sku) and is_integer(delta) do
    Repo.transaction(fn ->
      case Repo.get_by(Product, sku: sku) do
        nil -> 
          Repo.rollback(:product_not_found)
        product ->
          pid = product.id
          si = Repo.get_by(StockItem, product_id: pid) || 
               struct(StockItem, product_id: pid, quantity: 0)
          new_qty = si.quantity + delta
          if new_qty < 0, do: Repo.rollback(:insufficient_stock)
          
          changeset = 
            si
            |> Ecto.Changeset.cast(%{quantity: new_qty, product_id: pid}, [:quantity, :product_id])
            |> Ecto.Changeset.validate_required([:quantity, :product_id])
            |> Ecto.Changeset.validate_number(:quantity, greater_than_or_equal_to: 0)
          
          {:ok, saved} = (si.id && Repo.update(changeset)) || Repo.insert(changeset)
          saved
      end
    end)
  end
end

defmodule Supermarket.Cart do
  import Ecto.Query
  alias Supermarket.Repo
  alias Supermarket.Product
  alias Supermarket.Accounts.User
  alias Supermarket.Cart.CartItem
  alias Supermarket.Inventory

  def add_to_cart(username, sku, quantity \\ 1) 
      when is_binary(username) and is_integer(sku) and quantity > 0 do
    
    with {:ok, user} <- get_user_by_username(username),
         {:ok, product} <- get_product_by_sku(sku),
         {:ok, _} <- check_stock(sku, quantity) do
      
      case Repo.get_by(CartItem, user_id: user.id, product_id: product.id) do
        nil ->
          %CartItem{}
          |> CartItem.changeset(%{
            user_id: user.id,
            product_id: product.id,
            quantity: quantity
          })
          |> Repo.insert()
        
        cart_item ->
          new_qty = cart_item.quantity + quantity
          cart_item
          |> CartItem.changeset(%{quantity: new_qty})
          |> Repo.update()
      end
    end
  end

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

  def remove_from_cart(username, sku) when is_binary(username) and is_integer(sku) do
    with {:ok, user} <- get_user_by_username(username),
         {:ok, product} <- get_product_by_sku(sku) do
      
      case Repo.get_by(CartItem, user_id: user.id, product_id: product.id) do
        nil -> {:error, :not_in_cart}
        cart_item -> Repo.delete(cart_item)
      end
    end
  end

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

  def checkout(username) when is_binary(username) do
    Repo.transaction(fn ->
      case get_cart(username) do
        {:ok, %{items: []}} ->
          Repo.rollback(:empty_cart)
        
        {:ok, %{items: items, total: total}} ->
          Enum.each(items, fn item ->
            case Inventory.inc_stock_by_sku(item.sku, -item.quantity) do
              {:ok, _} -> :ok
              {:error, reason} -> Repo.rollback(reason)
            end
          end)
          
          clear_cart(username)
          
          {:ok, %{items_count: length(items), total: total}}
        
        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

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

defmodule CartTest do
  alias Supermarket.Cart

  def run do
    username = "test_user"
    
    IO.puts("\n=== Agregando productos al carrito ===")
    case Cart.add_to_cart(username, 10001, 2) do
      {:ok, _} -> IO.puts("✅ Producto 10001 agregado (qty: 2)")
      {:error, reason} -> IO.puts("Error: #{inspect(reason)}")
    end
    
    case Cart.add_to_cart(username, 10002, 1) do
      {:ok, _} -> IO.puts("✅ Producto 10002 agregado (qty: 1)")
      {:error, reason} -> IO.puts("Error: #{inspect(reason)}")
    end
    
    IO.puts("\n=== Ver carrito ===")
    case Cart.get_cart(username) do
      {:ok, cart} -> IO.inspect(cart, label: "Carrito")
      {:error, reason} -> IO.puts("Error: #{inspect(reason)}")
    end
    
    IO.puts("\n=== Actualizar cantidad ===")
    case Cart.update_quantity(username, 10001, 5) do
      {:ok, _} -> IO.puts("✅ Cantidad actualizada")
      {:error, reason} -> IO.puts("Error: #{inspect(reason)}")
    end
    
    IO.puts("\n=== Remover producto ===")
    case Cart.remove_from_cart(username, 10002) do
      {:ok, _} -> IO.puts("✅ Producto removido")
      {:error, reason} -> IO.puts("Error: #{inspect(reason)}")
    end
    
    case Cart.get_cart(username) do
      {:ok, updated} -> IO.inspect(updated, label: "Carrito actualizado")
      {:error, reason} -> IO.puts("Error: #{inspect(reason)}")
    end

    IO.puts("\n=== Probando checkout ===")
    case Cart.checkout(username) do
      {:ok, {:ok, result}} -> 
        IO.puts("✅ Compra exitosa!")
        IO.inspect(result, label: "Resultado")
      {:error, reason} -> 
        IO.puts("Error en checkout: #{inspect(reason)}")
    end
  end
end

{:ok, _} = Supermarket.Repo.start_link()
CartTest.run()