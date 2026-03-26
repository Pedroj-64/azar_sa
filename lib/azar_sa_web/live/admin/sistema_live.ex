defmodule AzarSaWeb.Admin.SistemaLive do
  @moduledoc """
  LiveView para gestión del sistema.
  Permite modificar la fecha del sistema y ejecutar sorteos pendientes.
  """

  use AzarSaWeb, :live_view

  alias AzarSa.Sistema.Fecha
  alias AzarSa.Servidores.ServidorCentral

  @impl true
  def mount(_params, _session, socket) do
    fecha_actual = Fecha.fecha_actual()
    sorteos = ServidorCentral.listar_sorteos()
    sorteos_pendientes = Enum.filter(sorteos, &(&1.estado == :pendiente))

    socket =
      socket
      |> assign(:page_title, "Sistema")
      |> assign(:fecha_actual, fecha_actual)
      |> assign(:nueva_fecha, Date.to_iso8601(fecha_actual))
      |> assign(:sorteos_pendientes, sorteos_pendientes)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <!-- Header -->
      <header class="bg-indigo-600 shadow">
        <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <div class="flex items-center">
            <.link navigate="/admin" class="text-white hover:text-indigo-200 mr-4">
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </.link>
            <h1 class="text-3xl font-bold text-white">Configuración del Sistema</h1>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <!-- Fecha del Sistema -->
          <div class="bg-white shadow sm:rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Fecha del Sistema</h3>
              
              <div class="bg-blue-50 border-l-4 border-blue-400 p-4 mb-4">
                <div class="flex">
                  <div class="flex-shrink-0">
                    <svg class="h-5 w-5 text-blue-400" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
                    </svg>
                  </div>
                  <div class="ml-3">
                    <p class="text-sm text-blue-700">
                      La fecha actual del sistema es: <strong><%= @fecha_actual %></strong>
                    </p>
                    <p class="text-xs text-blue-600 mt-1">
                      Al avanzar la fecha, se ejecutarán automáticamente todos los sorteos pendientes hasta esa fecha.
                    </p>
                  </div>
                </div>
              </div>

              <form phx-submit="actualizar_fecha" class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700">Nueva Fecha</label>
                  <input type="date" name="fecha" value={@nueva_fecha} 
                         class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                </div>
                
                <div class="flex space-x-3">
                  <button type="submit" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700">
                    Actualizar Fecha
                  </button>
                  <button type="button" phx-click="resetear_fecha" class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                    Resetear a Hoy
                  </button>
                </div>
              </form>
            </div>
          </div>

          <!-- Sorteos Pendientes -->
          <div class="bg-white shadow sm:rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                Sorteos Pendientes (<%= length(@sorteos_pendientes) %>)
              </h3>

              <%= if Enum.empty?(@sorteos_pendientes) do %>
                <p class="text-gray-500 text-sm">No hay sorteos pendientes.</p>
              <% else %>
                <ul class="divide-y divide-gray-200">
                  <%= for sorteo <- @sorteos_pendientes do %>
                    <li class="py-3">
                      <div class="flex justify-between items-center">
                        <div>
                          <p class="text-sm font-medium text-gray-900"><%= sorteo.nombre %></p>
                          <p class="text-xs text-gray-500">Fecha: <%= sorteo.fecha %></p>
                        </div>
                        <div class="flex items-center space-x-2">
                          <%= if Date.compare(sorteo.fecha, @fecha_actual) in [:lt, :eq] do %>
                            <span class="px-2 py-1 text-xs bg-yellow-100 text-yellow-800 rounded-full">
                              Listo para ejecutar
                            </span>
                          <% else %>
                            <span class="px-2 py-1 text-xs bg-gray-100 text-gray-600 rounded-full">
                              Futuro
                            </span>
                          <% end %>
                        </div>
                      </div>
                    </li>
                  <% end %>
                </ul>

                <div class="mt-4">
                  <button phx-click="ejecutar_todos" 
                          data-confirm="¿Ejecutar todos los sorteos pendientes hasta la fecha actual?"
                          class="w-full inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-green-600 hover:bg-green-700">
                    Ejecutar Sorteos Pendientes
                  </button>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Información del Sistema -->
          <div class="bg-white shadow sm:rounded-lg lg:col-span-2">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Información del Sistema</h3>
              
              <dl class="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div class="bg-gray-50 p-3 rounded-md">
                  <dt class="text-xs font-medium text-gray-500">Versión Elixir</dt>
                  <dd class="mt-1 text-sm text-gray-900"><%= System.version() %></dd>
                </div>
                <div class="bg-gray-50 p-3 rounded-md">
                  <dt class="text-xs font-medium text-gray-500">OTP</dt>
                  <dd class="mt-1 text-sm text-gray-900"><%= :erlang.system_info(:otp_release) %></dd>
                </div>
                <div class="bg-gray-50 p-3 rounded-md">
                  <dt class="text-xs font-medium text-gray-500">Procesos Activos</dt>
                  <dd class="mt-1 text-sm text-gray-900"><%= :erlang.system_info(:process_count) %></dd>
                </div>
                <div class="bg-gray-50 p-3 rounded-md">
                  <dt class="text-xs font-medium text-gray-500">Memoria Usada</dt>
                  <dd class="mt-1 text-sm text-gray-900"><%= format_memory(:erlang.memory(:total)) %></dd>
                </div>
              </dl>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("actualizar_fecha", %{"fecha" => fecha}, socket) do
    case Fecha.actualizar_fecha(fecha) do
      {:ok, nueva_fecha} ->
        # Ejecutar sorteos pendientes
        ServidorCentral.actualizar_fecha_sistema(fecha)

        sorteos = ServidorCentral.listar_sorteos()
        sorteos_pendientes = Enum.filter(sorteos, &(&1.estado == :pendiente))

        {:noreply,
         socket
         |> assign(:fecha_actual, nueva_fecha)
         |> assign(:nueva_fecha, Date.to_iso8601(nueva_fecha))
         |> assign(:sorteos_pendientes, sorteos_pendientes)
         |> put_flash(:info, "Fecha actualizada. Sorteos pendientes ejecutados.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("resetear_fecha", _params, socket) do
    case Fecha.resetear() do
      {:ok, fecha} ->
        {:noreply,
         socket
         |> assign(:fecha_actual, fecha)
         |> assign(:nueva_fecha, Date.to_iso8601(fecha))
         |> put_flash(:info, "Fecha reseteada a hoy")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("ejecutar_todos", _params, socket) do
    fecha = socket.assigns.fecha_actual
    ServidorCentral.actualizar_fecha_sistema(Date.to_iso8601(fecha))

    sorteos = ServidorCentral.listar_sorteos()
    sorteos_pendientes = Enum.filter(sorteos, &(&1.estado == :pendiente))

    {:noreply,
     socket
     |> assign(:sorteos_pendientes, sorteos_pendientes)
     |> put_flash(:info, "Sorteos ejecutados correctamente")}
  end

  defp format_memory(bytes) do
    cond do
      bytes >= 1_073_741_824 -> "#{Float.round(bytes / 1_073_741_824, 2)} GB"
      bytes >= 1_048_576 -> "#{Float.round(bytes / 1_048_576, 2)} MB"
      bytes >= 1024 -> "#{Float.round(bytes / 1024, 2)} KB"
      true -> "#{bytes} B"
    end
  end
end
