# Ejecutar con: elixir lib/create_product.exs "Nombre del producto" "Categoria" 450

Mix.install([
  {:ecto_sql, "~> 3.10"},
  {:postgrex, ">= 0.0.0"}
])

# Módulo del repositorio
defmodule Supermarket.Repo do
  use Ecto.Repo,
    otp_app: :supermarket,
    adapter: Ecto.Adapters.Postgres
end

# Cargar configuración de conexión (igual que config/dev.exs)
Application.put_env(:supermarket, Supermarket.Repo,
  username: "postgres",
  password: "Figu_dev_1",
  hostname: "34.46.167.102",
  database: "supermarket_dev",
  port: 5432,
  pool_size: 5,
  ssl: [verify: :verify_none]
)

# Schema del producto (debe coincidir con tu tabla products)
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

# Iniciar conexión al repositorio
{:ok, _pid} = Supermarket.Repo.start_link()

# Función para insertar producto
defmodule Supermarket.CLI do
  import Ecto.Changeset
  alias Supermarket.{Repo, Product}

  def create_product(attrs) do
    %Product{}
    |> cast(attrs, [:name, :sku, :category, :price, :active])
    |> validate_required([:name, :sku, :category, :price])
    |> unique_constraint(:sku)
    |> Repo.insert()
  end

  def get_next_sku do
    # Obtener el SKU máximo actual, si no existe ninguno, comenzar en 10000
    query = "SELECT COALESCE(MAX(sku), 10000) FROM products"
    result = Ecto.Adapters.SQL.query!(Repo, query, [])
    
    max_sku = result.rows |> List.first() |> List.first()
    
    # El siguiente SKU será max_sku + 1 (primer producto será 10001)
    max_sku + 1
  end
end

# Leer argumentos desde terminal
case System.argv() do
  [name, category, price_str] ->
    # Validar/parsear precio como entero
    case Integer.parse(price_str) do
      {price, ""} ->
        # Generar SKU automáticamente
        next_sku = Supermarket.CLI.get_next_sku()

        attrs = %{
          name: name,
          sku: next_sku,
          category: category,
          price: price,
          active: true
        }

        IO.puts("Generando producto con SKU: #{next_sku}")

        case Supermarket.CLI.create_product(attrs) do
          {:ok, product} ->
            IO.puts("✅ Producto creado correctamente:")
            IO.puts("   Nombre: #{product.name}")
            IO.puts("   SKU: #{product.sku}")
            IO.puts("   Categoría: #{product.category}")
            IO.puts("   Precio: $#{product.price}")

          {:error, changeset} ->
            IO.puts("Error al crear producto:")
            IO.inspect(changeset.errors)
        end

      _ ->
        IO.puts("El precio debe ser un número entero.")
        IO.puts("Uso: elixir lib/create_product.exs \"Nombre del producto\" \"Categoría\" <precio>")
    end

  _ ->
    IO.puts("Uso: elixir lib/create_product.exs \"Nombre del producto\" \"Categoría\" <precio>")
    IO.puts("Ejemplo: elixir lib/create_product.exs \"Manzana\" \"Frutas\" 450")
end