defmodule MiTiendaWebWeb.LoginLive do
  use MiTiendaWebWeb, :live_view

  alias MiTiendaWeb.Repo
  alias Supermarket.Accounts.User

  @form_schema %{"username" => "", "password" => ""}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: @form_schema, error: nil)}
  end

  @impl true
  def handle_event("login", %{"user" => params}, socket) do
    case Repo.get_by(User, username: params["username"]) do
      nil ->
        {:noreply, assign(socket, error: "Usuario o password incorrectos.", form: @form_schema)}

      user ->
        input_hash = :crypto.hash(:sha256, params["password"]) |> Base.encode16(case: :lower)

        if input_hash == user.password_hash do
          {:noreply,
           socket
           |> put_flash(:info, "Bienvenido de nuevo, #{user.username}!")
           # CONFIRMA QUE ESTA LINEA DIGA 'username'
           |> push_navigate(to: "/productos?user_id=#{user.username}")}
        else
          {:noreply, assign(socket, error: "Usuario o password incorrectos.", form: @form_schema)}
        end
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
        <h1 class="text-3xl font-bold text-center text-gray-900">Bienvenido de nuevo</h1>
        <p class="mt-2 text-center text-gray-500">Ingresa a tu cuenta para continuar</p>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-6 shadow-sm rounded-xl border border-gray-200 mx-4 sm:mx-0">
          <.form for={@form} phx-submit="login" as={:user} class="space-y-5">
            <%= if assigns.error do %>
              <div class="bg-red-50 border-l-4 border-red-500 text-red-700 px-4 py-3 rounded-r flex items-center gap-3">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <%= assigns.error %>
              </div>
            <% end %>
            
            <div>
              <label class="block text-gray-700 text-sm font-medium mb-2">Usuario</label>
              <input 
                type="text" 
                name="user[username]" 
                value={@form["username"]} 
                required 
                placeholder="Ingresa tu usuario"
                class="w-full px-4 py-3 border border-gray-300 rounded-lg text-gray-900 focus:ring-2 focus:ring-gray-900 focus:border-gray-900 transition-colors" 
              />
            </div>
            
            <div>
              <label class="block text-gray-700 text-sm font-medium mb-2">Contrasena</label>
              <input 
                type="password" 
                name="user[password]" 
                value={@form["password"]} 
                required 
                placeholder="Ingresa tu contrasena"
                class="w-full px-4 py-3 border border-gray-300 rounded-lg text-gray-900 focus:ring-2 focus:ring-gray-900 focus:border-gray-900 transition-colors" 
              />
            </div>
            
            <div class="pt-2">
              <button 
                type="submit" 
                class="w-full bg-gray-900 text-white font-semibold py-3 px-4 rounded-lg hover:bg-gray-800 transition-colors"
              >
                Iniciar Sesion
              </button>
            </div>
          </.form>
          
          <div class="mt-6 text-center">
            <p class="text-gray-500 text-sm">
              No tienes cuenta? 
              <a href="/register" class="text-gray-900 font-semibold hover:underline">Crear cuenta</a>
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