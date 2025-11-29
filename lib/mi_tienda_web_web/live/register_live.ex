defmodule MiTiendaWebWeb.RegisterLive do
  use MiTiendaWebWeb, :live_view

  alias MiTiendaWeb.Repo
  alias Supermarket.Accounts.User
  
  # Necesario para <.form> y <.input>
  import MiTiendaWebWeb.CoreComponents 

  @impl true
  def mount(_params, _session, socket) do
    changeset = User.registration_changeset(%User{}, %{})
    {:ok, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    %User{}
    |> User.registration_changeset(user_params)
    |> Repo.insert()
    |> case do
      # === CAMBIO IMPORTANTE AQUI ===
      # Antes tenias {:ok, _user}, ahora usamos {:ok, user} para leer el nombre
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Usuario creado con exito.")
         # Redirigimos usando el username para que no sea 'nil'
         |> push_navigate(to: "/productos?user_id=#{user.username}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 flex flex-col justify-center">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <!-- Logo -->
        <div class="flex justify-center mb-6">
          <div class="w-16 h-16 bg-black rounded-2xl flex items-center justify-center">
            <span class="text-white font-bold text-3xl">T</span>
          </div>
        </div>
        <h1 class="text-3xl font-bold text-center text-gray-900">Crear cuenta</h1>
        <p class="mt-2 text-center text-gray-500">Unete a nuestra tienda hoy</p>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-6 shadow-sm rounded-xl border border-gray-200 mx-4 sm:mx-0">
          <.form for={@form} phx-submit="save" class="space-y-5">
            
            <div>
              <label class="block text-gray-700 text-sm font-medium mb-2">Usuario</label>
              <.input 
                field={@form[:username]} 
                type="text" 
                placeholder="Elige un nombre de usuario"
                class="w-full px-4 py-3 border border-gray-300 rounded-lg text-gray-900 focus:ring-2 focus:ring-gray-900 focus:border-gray-900 transition-colors" 
              />
              <%= for msg <- @form[:username].errors do %>
                <p class="text-red-500 text-sm mt-1 flex items-center gap-1">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <%= elem(msg, 0) %>
                </p>
              <% end %>
            </div>

            <div>
              <label class="block text-gray-700 text-sm font-medium mb-2">Contrasena</label>
              <.input 
                field={@form[:password]} 
                type="password" 
                placeholder="Minimo 4 caracteres"
                class="w-full px-4 py-3 border border-gray-300 rounded-lg text-gray-900 focus:ring-2 focus:ring-gray-900 focus:border-gray-900 transition-colors" 
              />
              <%= for msg <- @form[:password].errors do %>
                <p class="text-red-500 text-sm mt-1 flex items-center gap-1">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <%= elem(msg, 0) %>
                </p>
              <% end %>
            </div>

            <div>
              <label class="block text-gray-700 text-sm font-medium mb-2">Confirmar Contrasena</label>
              <.input 
                field={@form[:password_confirmation]} 
                type="password" 
                placeholder="Repite tu contrasena"
                class="w-full px-4 py-3 border border-gray-300 rounded-lg text-gray-900 focus:ring-2 focus:ring-gray-900 focus:border-gray-900 transition-colors" 
              />
              <%= for msg <- @form[:password_confirmation].errors do %>
                <p class="text-red-500 text-sm mt-1 flex items-center gap-1">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <%= elem(msg, 0) %>
                </p>
              <% end %>
            </div>

            <div class="pt-2">
              <button 
                type="submit" 
                class="w-full bg-gray-900 text-white font-semibold py-3 px-4 rounded-lg hover:bg-gray-800 transition-colors"
              >
                Crear Cuenta
              </button>
            </div>
          </.form>
          
          <div class="mt-6 text-center">
            <p class="text-gray-500 text-sm">
              Ya tienes cuenta? 
              <a href="/login" class="text-gray-900 font-semibold hover:underline">Iniciar sesion</a>
            </p>
          </div>
        </div>
        
        <p class="mt-8 text-center text-gray-400 text-sm">
          TIENDA &copy; 2025
        </p>
      </div>
    </div>
    """
  end
end