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
    <div class="container mx-auto p-8 max-w-md">
      <h1 class="text-3xl font-bold mb-6 text-center">Crear Cuenta</h1>

      <div class="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
        <.form for={@form} phx-submit="save" class="space-y-4">
          
          <div>
            <label class="block text-gray-700 text-sm font-bold mb-2">Usuario</label>
            <.input field={@form[:username]} type="text" class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" />
            
            <%= for msg <- @form[:username].errors do %>
              <p class="text-red-500 text-xs italic"><%= elem(msg, 0) %></p>
            <% end %>
          </div>

          <div>
            <label class="block text-gray-700 text-sm font-bold mb-2">Password</label>
            <.input field={@form[:password]} type="password" class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" />
            
            <%= for msg <- @form[:password].errors do %>
              <p class="text-red-500 text-xs italic"><%= elem(msg, 0) %></p>
            <% end %>
          </div>

          <div>
            <label class="block text-gray-700 text-sm font-bold mb-2">Confirmar Password</label>
            <.input field={@form[:password_confirmation]} type="password" class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" />
            
            <%= for msg <- @form[:password_confirmation].errors do %>
              <p class="text-red-500 text-xs italic"><%= elem(msg, 0) %></p>
            <% end %>
          </div>

          <div class="flex items-center justify-between mt-6">
            <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline w-full">
              Registrarse
            </button>
          </div>

          <a href="/login" class="text-center block text-sm text-blue-500 hover:text-blue-800">Ya tengo cuenta</a>

        </.form>
      </div>
    </div>
    """
  end
end