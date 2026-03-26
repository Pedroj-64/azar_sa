defmodule AzarSaWeb.Jugador.LoginLive do
  use AzarSaWeb, :live_view
  alias AzarSa.Clientes

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Iniciar Sesión")
      |> assign(:error, nil)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-purple-600 to-indigo-700 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8 bg-white p-8 rounded-xl shadow-2xl">
        <div>
          <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Azar S.A.
          </h2>
          <p class="mt-2 text-center text-sm text-gray-600">
            Inicia sesión para jugar
          </p>
        </div>

        <%= if @error do %>
          <div class="bg-red-50 border-l-4 border-red-400 p-4">
            <p class="text-sm text-red-700"><%= @error %></p>
          </div>
        <% end %>

        <form phx-submit="login" class="mt-8 space-y-6">
          <div class="rounded-md shadow-sm -space-y-px">
            <div>
              <label for="documento" class="sr-only">Documento</label>
              <input id="documento" name="documento" type="text" required 
                     class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm" 
                     placeholder="Número de documento">
            </div>
            <div>
              <label for="password" class="sr-only">Contraseña</label>
              <input id="password" name="password" type="password" required 
                     class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm" 
                     placeholder="Contraseña">
            </div>
          </div>

          <div>
            <button type="submit" 
                    class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              Iniciar Sesión
            </button>
          </div>
        </form>

        <div class="text-center">
          <.link navigate="/registro" class="font-medium text-indigo-600 hover:text-indigo-500">
            ¿No tienes cuenta? Regístrate
          </.link>
        </div>

        <div class="border-t pt-4">
          <.link navigate="/admin" class="block text-center text-sm text-gray-500 hover:text-gray-700">
            Acceso Administrador
          </.link>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("login", %{"documento" => documento, "password" => password}, socket) do
    case Clientes.autenticar(documento, password) do
      {:ok, cliente} ->
        {:noreply,
         socket
         |> put_flash(:info, "Bienvenido, #{cliente.nombre}")
         |> redirect(to: "/jugador?cliente_id=#{cliente.id}")}

      {:error, _} ->
        {:noreply, assign(socket, :error, "Documento o contraseña incorrectos")}
    end
  end
end
