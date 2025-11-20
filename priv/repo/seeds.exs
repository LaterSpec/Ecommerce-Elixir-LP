# --- Atajos ---
alias MiTiendaWeb.Repo
alias Supermarket.Inventory
alias Supermarket.Product
alias Supermarket.Inventory.StockItem
alias Supermarket.Cart.CartItem
alias Supermarket.Accounts.User # <--- NUEVO ALIAS

IO.puts "Limpiando la base de datos..."
# Borramos todo para empezar limpio
Repo.delete_all(StockItem)
Repo.delete_all(CartItem)
Repo.delete_all(Product)
Repo.delete_all(User) # <--- Borramos usuarios viejos tambien

IO.puts "Creando productos..."

{:ok, prod1} =
  %Product{}
  |> Product.changeset(%{
    sku: 10001,
    name: "Manzana Roja",
    category: "Frutas",
    price: 150
  })
  |> Repo.insert()

{:ok, prod2} =
  %Product{}
  |> Product.changeset(%{
    sku: 10002,
    name: "Leche Entera",
    category: "Lacteos",
    price: 320
  })
  |> Repo.insert()

{:ok, prod3} =
  %Product{}
  |> Product.changeset(%{
    sku: 10003,
    name: "Pan de Molde",
    category: "Panaderia",
    price: 275
  })
  |> Repo.insert()

IO.puts "Productos creados. Asignando stock..."

Inventory.set_stock_by_sku(prod1.sku, 50)
Inventory.set_stock_by_sku(prod2.sku, 30)
Inventory.set_stock_by_sku(prod3.sku, 40)

# --- NUEVA SECCION: CREAR USUARIO ---
IO.puts "Creando usuario de prueba..."

%User{}
|> User.registration_changeset(%{
  username: "invitado",
  password: "1234",
  password_confirmation: "1234"
})
|> Repo.insert!()

IO.puts "Base de datos sembrada con exito!"