# Ejecutar con: mix run lib/welcome.exs
alias Supermarket.Accounts
alias Supermarket.Cart

defmodule Supermarket.WelcomeCLI do
  def run, do: loop_welcome()

  ## ================== WELCOME ==================
  defp loop_welcome do
    banner()
    case prompt("Selecciona una opción: ") do
      "1" -> do_login()
      "2" -> do_signup()
      "0" -> IO.puts("\n Saliendo. ¡Gracias por visitar la tienda!\n")
      _   -> puts("\nOpción inválida.\n") && pause() && loop_welcome()
    end
  end

  defp banner do
    IO.puts("""
    =========================================
               🛒  SUPERMARKET CLI
    =========================================
    1) Login
    2) Sign in (crear cuenta)
    0) Salir
    """)
  end

  ## ================== AUTH ==================
  defp do_login do
    IO.puts("\n=== LOGIN ===")
    username = prompt("Usuario: ")
    password = prompt("Contraseña: ", hidden: true)

    case Accounts.authenticate(username, password) do
      {:ok, :authenticated} ->
        IO.puts("\n✅ Inicio de sesión correcto. ¡Bienvenido, #{username}!\n")
        pause()
        if username == "ADMIN", do: loop_admin(username), else: loop_user(username)

      {:error, :not_found} ->
        IO.puts("\n❌ Usuario no encontrado.\n") && pause() && loop_welcome()

      {:error, :invalid_password} ->
        IO.puts("\n❌ Contraseña incorrecta.\n") && pause() && loop_welcome()
    end
  end

  defp do_signup do
    IO.puts("\n=== SIGN IN (crear cuenta) ===")
    username = prompt("Elige un usuario: ")
    password = prompt("Contraseña: ", hidden: true)
    confirm  = prompt("Repite la contraseña: ", hidden: true)

    case Accounts.register_user(%{username: username, password: password, password_confirmation: confirm}) do
      {:ok, _user} ->
        IO.puts("\n✅ Cuenta creada correctamente. Ahora puedes iniciar sesión.\n")
      {:error, changeset} ->
        IO.puts("\n❌ No se pudo crear la cuenta:")
        Enum.each(changeset.errors, fn {field, {msg, _}} -> IO.puts("   - #{field}: #{msg}") end)
        IO.puts("")
    end

    pause()
    loop_welcome()
  end

  ## ================== MENÚS POR ROL ==================
  # ----- ADMIN -----
  defp loop_admin(username) do
    IO.puts("""
    ================= ADMIN =================
    1) Listar productos
    2) Buscar productos por categoría
    3) Crear producto
    4) Ver stock
    5) Setear stock por SKU
    9) Cerrar sesión
    0) Salir
    """)

    case prompt("Selecciona una opción: ") do
        "1" -> run_list()            && pause() && loop_admin(username)
        "2" -> run_search_flow()     && pause() && loop_admin(username)
        "3" -> run_create_flow()     && pause() && loop_admin(username)
        "4" -> run_stock_show_flow() && pause() && loop_admin(username)
        "5" -> run_stock_set_flow()  && pause() && loop_admin(username)
        "9" -> IO.puts("\n Sesión cerrada.\n") && pause() && loop_welcome()
        "0" -> IO.puts("\n Saliendo. ¡Gracias por visitar la tienda!\n")
        _   -> puts("\nOpción inválida.\n") && pause() && loop_admin(username)
    end
  end

  # ----- USUARIO NORMAL -----
  defp loop_user(username) do
    IO.puts("""
    ================= USUARIO =================
    1) Listar productos
    2) Buscar productos por categoría
    3) Ver mi carrito 
    4) Agregar al carrito
    5) Actualizar cantidad en carrito
    6) Remover producto del carrito
    7) Vaciar carrito
    8) Checkout (comprar)
    9) Cerrar sesión
    0) Salir
    """)

    case prompt("Selecciona una opción: ") do
      "1" -> run_list()                  && pause() && loop_user(username)
      "2" -> run_search_flow()           && pause() && loop_user(username)
      "3" -> run_view_cart(username)     && pause() && loop_user(username)
      "4" -> run_add_to_cart(username)   && pause() && loop_user(username)
      "5" -> run_update_cart(username)   && pause() && loop_user(username)
      "6" -> run_remove_from_cart(username) && pause() && loop_user(username)
      "7" -> run_clear_cart(username)    && pause() && loop_user(username)
      "8" -> run_checkout(username)      && pause() && loop_user(username)
      "9" -> IO.puts("\nSesión cerrada.\n") && pause() && loop_welcome()
      "0" -> IO.puts("\nSaliendo. ¡Gracias por visitar la tienda!\n")
      _   -> puts("\nOpción inválida.\n") && pause() && loop_user(username)
    end
  end

  ## ================== ACCIONES PRODUCTOS ==================
  defp run_list do
    run_elixir(["lib/list_products.exs"])
  end

  defp run_search_flow do
    IO.puts("\n=== Buscar productos ===")
    IO.puts("1) Buscar por categoría (una o varias separadas por coma)")
    IO.puts("2) Listar categorias")
    case prompt("Opción: ") do
      "1" ->
        cats = prompt("Categoría(s): ")
        if String.trim(cats) == "" do
          IO.puts("⚠️ Debes ingresar al menos una categoria.")
        else
          run_elixir(["lib/search_products.exs", cats])
        end
      "2" ->
        run_elixir(["lib/search_products.exs", "--list-categories"])
      _ ->
        IO.puts("Opción inválida.")
    end
  end

  defp run_create_flow do
    IO.puts("\n=== Crear producto ===")
    name = prompt("Nombre: ")
    category = prompt("Categoria: ")
    price =
      case prompt("Precio: ") |> Integer.parse() do
        {n, ""} -> Integer.to_string(n)
        _ -> IO.puts("⚠️ Precio invalido."); nil
      end

    cond do
      String.trim(name) == "" or String.trim(category) == "" or is_nil(price) ->
        IO.puts("❌ Datos inválidos. Intenta de nuevo.")
      true ->
        run_elixir(["lib/create_product.exs", name, category, price])
    end
  end

  defp run_stock_show_flow do
    IO.puts("\n=== Ver stock ===")
    IO.puts("1) Ver TODO el stock")
    IO.puts("2) Ver stock por SKU")
    case prompt("Opción: ") do
      "1" ->
        run_elixir(["lib/stock_show.exs"])
      "2" ->
        sku_str = prompt("SKU (entero): ")
        case Integer.parse(sku_str) do
          {sku, ""} when sku >= 0 ->
            run_elixir(["lib/stock_show.exs", Integer.to_string(sku)])
          _ ->
            IO.puts("⚠️ SKU inválido.")
            false
        end
      _ ->
        IO.puts("Opción inválida.")
        false
    end
  end

  defp run_stock_set_flow do
    IO.puts("\n=== Setear stock por SKU ===")
    sku_str = prompt("SKU (entero): ")
    qty_str = prompt("Cantidad (>= 0): ")

    with {sku, ""} <- Integer.parse(sku_str),
         {qty, ""} <- Integer.parse(qty_str),
         true <- qty >= 0 do
      run_elixir(["lib/stock_set.exs", Integer.to_string(sku), Integer.to_string(qty)])
    else
      _ ->
        IO.puts("⚠️ Datos inválidos. Debes ingresar SKU entero y cantidad >= 0.")
        false
    end
  end

  ## ================== ACCIONES CARRITO ==================
  defp run_view_cart(username) do
    case Cart.get_cart(username) do
      {:ok, %{items: [], total: _}} ->
        IO.puts("\n Tu carrito está vacío.\n")
      {:ok, %{items: items, total: total}} ->
        IO.puts("\n TU CARRITO:")
        IO.puts(String.duplicate("=", 80))
        IO.puts(String.pad_trailing("Producto", 30) <> 
                String.pad_trailing("SKU", 10) <> 
                String.pad_trailing("Precio", 12) <> 
                String.pad_trailing("Cant", 8) <> 
                "Subtotal")
        IO.puts(String.duplicate("=", 80))
        
        Enum.each(items, fn item ->
          IO.puts(
            String.pad_trailing(item.product_name, 30) <>
            String.pad_trailing("#{item.sku}", 10) <>
            String.pad_trailing("$#{item.price}", 12) <>
            String.pad_trailing("x#{item.quantity}", 8) <>
            "$#{item.subtotal}"
          )
        end)
        
        IO.puts(String.duplicate("=", 80))
        IO.puts("TOTAL: $#{total}\n")
      {:error, reason} ->
        IO.puts("❌ Error: #{inspect(reason)}")
    end
    true
  end

  defp run_add_to_cart(username) do
    IO.puts("\n=== Agregar al carrito ===")
    sku_str = prompt("SKU del producto: ")
    qty_str = prompt("Cantidad: ")
    
    with {sku, ""} <- Integer.parse(sku_str),
         {qty, ""} <- Integer.parse(qty_str),
         true <- qty > 0 do
      
      case Cart.add_to_cart(username, sku, qty) do
        {:ok, _} -> IO.puts("✅ Producto agregado al carrito.")
        {:error, :insufficient_stock} -> IO.puts("❌ Stock insuficiente.")
        {:error, :product_not_found} -> IO.puts("❌ Producto no encontrado.")
        {:error, reason} -> IO.puts("❌ Error: #{inspect(reason)}")
      end
    else
      _ -> IO.puts("⚠️  Datos inválidos. SKU y cantidad deben ser números enteros positivos.")
    end
    true
  end

  defp run_update_cart(username) do
    IO.puts("\n=== Actualizar cantidad ===")
    sku_str = prompt("SKU del producto: ")
    qty_str = prompt("Nueva cantidad: ")
    
    with {sku, ""} <- Integer.parse(sku_str),
         {qty, ""} <- Integer.parse(qty_str),
         true <- qty > 0 do
      
      case Cart.update_quantity(username, sku, qty) do
        {:ok, _} -> IO.puts("✅ Cantidad actualizada.")
        {:error, :not_in_cart} -> IO.puts("❌ Producto no está en tu carrito.")
        {:error, :insufficient_stock} -> IO.puts("❌ Stock insuficiente.")
        {:error, reason} -> IO.puts("❌ Error: #{inspect(reason)}")
      end
    else
      _ -> IO.puts("⚠️  Datos inválidos.")
    end
    true
  end

  defp run_remove_from_cart(username) do
    IO.puts("\n=== Remover producto ===")
    sku_str = prompt("SKU del producto: ")
    
    case Integer.parse(sku_str) do
      {sku, ""} ->
        case Cart.remove_from_cart(username, sku) do
          {:ok, _} -> IO.puts("✅ Producto removido del carrito.")
          {:error, :not_in_cart} -> IO.puts("❌ Producto no está en tu carrito.")
          {:error, reason} -> IO.puts("❌ Error: #{inspect(reason)}")
        end
      _ ->
        IO.puts("⚠️  SKU inválido.")
    end
    true
  end

  defp run_clear_cart(username) do
    confirmacion = prompt("¿Estás seguro de vaciar tu carrito? (s/n): ")
    
    if String.downcase(confirmacion) == "s" do
      case Cart.clear_cart(username) do
        {:ok, count} -> IO.puts("✅ Carrito vaciado (#{count} productos removidos).")
        {:error, reason} -> IO.puts("❌ Error: #{inspect(reason)}")
      end
    else
      IO.puts("❌ Operación cancelada.")
    end
    true
  end

  defp run_checkout(username) do
    IO.puts("\n=== CHECKOUT ===")
    
    # Mostrar carrito antes de comprar
    case Cart.get_cart(username) do
      {:ok, %{items: [], total: _}} ->
        IO.puts("❌ Tu carrito está vacío.")
        true
      {:ok, %{items: items, total: total}} ->
        IO.puts("\nResumen de compra:")
        IO.puts(String.duplicate("-", 60))
        Enum.each(items, fn item ->
          IO.puts("#{item.product_name} x#{item.quantity} = $#{item.subtotal}")
        end)
        IO.puts(String.duplicate("-", 60))
        IO.puts("TOTAL A PAGAR: $#{total}\n")
        
        confirmacion = prompt("¿Confirmar compra? (s/n): ")
        
        if String.downcase(confirmacion) == "s" do
          case Cart.checkout(username) do
            {:ok, {:ok, %{items_count: count, total: total}}} ->
              IO.puts("\n" <> String.duplicate("=", 60))
              IO.puts("✅ ¡COMPRA EXITOSA!")
              IO.puts("   Productos comprados: #{count}")
              IO.puts("   Total pagado: $#{total}")
              IO.puts("   El stock ha sido actualizado.")
              IO.puts(String.duplicate("=", 60) <> "\n")
            {:error, :empty_cart} ->
              IO.puts("❌ Tu carrito está vacío.")
            {:error, :insufficient_stock} ->
              IO.puts("❌ Stock insuficiente para uno o más productos.")
            {:error, reason} ->
              IO.puts("❌ Error en checkout: #{inspect(reason)}")
          end
        else
          IO.puts("❌ Compra cancelada.")
        end
        true
      {:error, reason} ->
        IO.puts("❌ Error: #{inspect(reason)}")
        true
    end
  end

  ## ================== UTILS ==================
  defp run_elixir(args) do
    case System.cmd("elixir", args, stderr_to_stdout: true) do
      {out, 0} -> IO.binwrite(out) && true
      {out, _} -> IO.binwrite(out) && false
    end
  end 

  defp prompt(label, opts \\ []) do
    IO.write(label)
    input =
      if opts[:hidden] do
        IO.gets("")
      else
        IO.gets("")
      end

    case input do
      nil -> ""
      bin -> String.trim(bin)
    end
  end

  defp puts(s), do: IO.puts(s)
  defp pause, do: (IO.write("Presiona ENTER para continuar..."); IO.gets(""); :ok)
end

Supermarket.WelcomeCLI.run()