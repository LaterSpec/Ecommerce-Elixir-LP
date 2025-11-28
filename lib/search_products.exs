# Usos:
#   elixir lib/search_products.exs "Electrodomestico"
#   elixir lib/search_products.exs "Electro,Linea Blanca"   
#   elixir lib/search_products.exs --list-categories        # lista categorías únicas

Mix.install([
  {:ecto_sql, "~> 3.10"},
  {:postgrex, ">= 0.0.0"}
])

defmodule Supermarket.Repo do
  use Ecto.Repo,
    otp_app: :supermarket,
    adapter: Ecto.Adapters.Postgres
end

Application.put_env(:supermarket, Supermarket.Repo,
  username: "postgres",
  password: "Figu_dev_1",
  hostname: "34.46.167.102",
  database: "supermarket_dev",
  port: 5432,
  pool_size: 5,
  ssl: [verify: :verify_none]
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

{:ok, _pid} = Supermarket.Repo.start_link()

defmodule Supermarket.CLI do
  import Ecto.Query
  alias Supermarket.{Repo, Product}

  def run(["--list-categories"]) do
    query =
      from p in Product,
        where: not is_nil(p.category) and p.category != "",
        distinct: true,
        select: p.category,
        order_by: [asc: p.category]

    case Repo.all(query) do
      [] ->
        IO.puts("No hay categorías registradas.")

      cats ->
        IO.puts("Categorías:")
        Enum.each(cats, &IO.puts("- " <> &1))
    end
  end

  def run([cats_arg]) do
    # Permite "Electrodomestico" o "Electro,Linea Blanca"
    cats =
      cats_arg
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    if cats == [] do
      IO.puts("Debes indicar al menos una categoría.")
      usage()
    else
      search_by_categories(cats)
    end
  end

  def run(_), do: usage()

  defp usage do
    IO.puts("Uso:")
    IO.puts("  elixir lib/search_products.exs \"Categoria\"")
    IO.puts("  elixir lib/search_products.exs \"Cat1,Cat2\"")
    IO.puts("  elixir lib/search_products.exs --list-categories")
  end

  defp search_by_categories(cats) do
    # Búsqueda case-insensitive con coincidencia parcial por cada término
    dynamic =
      Enum.reduce(cats, false, fn term, dyn ->
        ilike_term = "%#{term}%"
        dynamic([p], ^dyn or ilike(p.category, ^ilike_term))
      end)

    query =
      from p in Product,
        where: ^dynamic,
        order_by: [asc: p.name, asc: p.id]

    products = Repo.all(query)

    if Enum.empty?(products) do
      IO.puts("No se encontraron productos para categorías: #{Enum.join(cats, ", ")}")
    else
      IO.puts("Productos (#{Enum.join(cats, ", ")}):\n")
      Enum.each(products, fn p ->
        IO.puts("ID: #{p.id}")
        IO.puts("Nombre: #{p.name}")
        IO.puts("SKU: #{p.sku}")
        IO.puts("Categoría: #{p.category}")
        IO.puts("Precio: $#{p.price}")
        IO.puts("Activo: #{if p.active, do: "Sí", else: "No"}")
        IO.puts("Creado: #{p.inserted_at}")
        IO.puts("-----------------------------")
      end)
    end
  end
end

Supermarket.CLI.run(System.argv())
