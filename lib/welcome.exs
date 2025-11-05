# Ejecutar con: mix run lib/welcome.exs
alias Supermarket.Accounts

defmodule Supermarket.WelcomeCLI do
  def run, do: loop_welcome()

  ## ================== WELCOME ==================
  defp loop_welcome do
    banner()
    case prompt("Selecciona una opción: ") do
      "1" -> do_login()
      "2" -> do_signup()
      "0" -> IO.puts("\n👋 Saliendo. ¡Gracias por visitar la tienda!\n")
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
        "9" -> IO.puts("\n🔒 Sesión cerrada.\n") && pause() && loop_welcome()
        "0" -> IO.puts("\n👋 Saliendo. ¡Gracias por visitar la tienda!\n")
        _   -> puts("\nOpción inválida.\n") && pause() && loop_admin(username)
    end
  end


  # ----- USUARIO NORMAL -----
  defp loop_user(username) do
    IO.puts("""
    ================= USUARIO =================
    1) Listar productos
    2) Buscar productos por categoría
    9) Cerrar sesión
    0) Salir
    """)

    case prompt("Selecciona una opción: ") do
      "1" -> run_list()        && pause() && loop_user(username)
      "2" -> run_search_flow() && pause() && loop_user(username)
      "9" -> IO.puts("\n🔒 Sesión cerrada.\n") && pause() && loop_welcome()
      "0" -> IO.puts("\n👋 Saliendo. ¡Gracias por visitar la tienda!\n")
      _   -> puts("\nOpción inválida.\n") && pause() && loop_user(username)
    end
  end

  ## ================== ACCIONES ==================
  # Listar productos
  defp run_list do
    run_elixir(["lib/list_products.exs"])
  end

  # Buscar productos (categoría o listar categorias)
  defp run_search_flow do
    IO.puts("\n=== Buscar productos ===")
    IO.puts("1) Buscar por categoría (una o varias separadas por coma)")
    IO.puts("2) Listar categorias")
    case prompt("Opción: ") do
      "1" ->
        cats = prompt("Categoría(s): ")
        if String.trim(cats) == "" do
          IO.puts("⚠️  Debes ingresar al menos una categoria.")
        else
          run_elixir(["lib/search_products.exs", cats])
        end
      "2" ->
        run_elixir(["lib/search_products.exs", "--list-categories"])
      _ ->
        IO.puts("Opción inválida.")
    end
  end

  # Crear producto (ADMIN)
  defp run_create_flow do
    IO.puts("\n=== Crear producto ===")
    name = prompt("Nombre: ")
    category = prompt("Categoria: ")
    price =
      case prompt("Precio: ") |> Integer.parse() do
        {n, ""} -> Integer.to_string(n)
        _ -> IO.puts("⚠️  Precio invalido."); nil
      end

    cond do
      String.trim(name) == "" or String.trim(category) == "" or is_nil(price) ->
        IO.puts("❌ Datos inválidos. Intenta de nuevo.")
      true ->
        # Llama a tu script: elixir lib/create_product.exs "Nombre" "Categoria" 450
        run_elixir(["lib/create_product.exs", name, category, price])
    end
  end

    # Ver stock (todo o por SKU)
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
                IO.puts("⚠️  SKU inválido.")
                false
            end
            _ ->
            IO.puts("Opción inválida.")
            false
        end
        end

        # Setear stock por SKU (cantidad exacta)
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
            IO.puts("⚠️  Datos inválidos. Debes ingresar SKU entero y cantidad >= 0.")
            false
        end
    end



  ## ================== UTILS ==================
  defp run_elixir(args) do
    # Ejecuta: elixir <args...> y muestra salida/errores
    case System.cmd("elixir", args, stderr_to_stdout: true) do
      {out, 0} -> IO.binwrite(out) && true
      {out, _} -> IO.binwrite(out) && false
    end
  end

  defp prompt(label, opts \\ []) do
    IO.write(label)
    input =
      if opts[:hidden] do
        # Consola básica: no oculta caracteres. Para el curso está bien.
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
