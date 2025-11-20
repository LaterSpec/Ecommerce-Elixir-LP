defmodule MiTiendaWebWeb.LoginLive do
  use MiTiendaWebWeb, :live_view

  import Phoenix.LiveView.Socket
  import MiTiendaWebWeb.CoreComponents
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
    <div class="container mx-auto p-8 max-w-md">
      <h1 class="text-3xl font-bold mb-6 text-center">Iniciar Sesion</h1>
      <div class="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4">
        <.form for={@form} phx-submit="login" as={:user} class="space-y-4">
          <%= if assigns.error do %>
            <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative">
              <%= assigns.error %>
            </div>
          <% end %>
          <div>
            <label class="block text-gray-700 text-sm font-bold mb-2">Usuario</label>
            <input type="text" name="user[username]" value={@form["username"]} required class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" />
          </div>
          <div>
            <label class="block text-gray-700 text-sm font-bold mb-2">Password</label>
            <input type="password" name="user[password]" value={@form["password"]} required class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" />
          </div>
          <div class="flex items-center justify-between mt-6">
            <button type="submit" class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline w-full">
              Entrar
            </button>
          </div>
          <a href="/register" class="text-center block text-sm text-blue-500 hover:text-blue-800">No tengo cuenta</a>
        </.form>
      </div>
    </div>
    """
  end
end