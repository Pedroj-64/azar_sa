defmodule AzarSaWeb.Jugador.RegistroLive do
  use AzarSaWeb, :live_view
  alias AzarSa.Clientes

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Registro")
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
            Crear Cuenta
          </h2>
          <p class="mt-2 text-center text-sm text-gray-600">
            Regístrate para participar en los sorteos
          </p>
        </div>

        <%= if @error do %>
          <div class="bg-red-50 border-l-4 border-red-400 p-4">
            <p class="text-sm text-red-700"><%= @error %></p>
          </div>
        <% end %>

        <form phx-submit="registrar" class="mt-8 space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">Nombre completo</label>
            <input name="nombre" type="text" required 
                   class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Documento de identidad</label>
            <input name="documento" type="text" required 
                   class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700">Contraseña</label>
            <input name="password" type="password" required minlength="6"
                   class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
          </div>

          <fieldset class="border rounded-md p-4">
            <legend class="text-sm font-medium text-gray-700 px-2">Tarjeta de Crédito (simulada)</legend>
            <div class="space-y-3">
              <input name="tarjeta_numero" type="text" placeholder="Número de tarjeta" 
                     class="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
              <div class="grid grid-cols-2 gap-3">
                <input name="tarjeta_vencimiento" type="text" placeholder="MM/AA" 
                       class="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
                <input name="tarjeta_cvv" type="text" placeholder="CVV" 
                       class="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
              </div>
            </div>
          </fieldset>

          <div>
            <button type="submit" 
                    class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              Crear Cuenta
            </button>
          </div>
        </form>

        <div class="text-center">
          <.link navigate="/login" class="font-medium text-indigo-600 hover:text-indigo-500">
            ¿Ya tienes cuenta? Inicia sesión
          </.link>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("registrar", params, socket) do
    cliente_params = %{
      nombre: params["nombre"],
      documento: params["documento"],
      password: params["password"],
      tarjeta_credito: %{
        numero: params["tarjeta_numero"],
        vencimiento: params["tarjeta_vencimiento"],
        cvv: params["tarjeta_cvv"]
      }
    }

    case Clientes.registrar(cliente_params) do
      {:ok, cliente} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cuenta creada exitosamente")
         |> redirect(to: "/jugador?cliente_id=#{cliente.id}")}

      {:error, :documento_ya_registrado} ->
        {:noreply, assign(socket, :error, "Este documento ya está registrado")}

      {:error, _} ->
        {:noreply, assign(socket, :error, "Error al crear la cuenta")}
    end
  end
end
