defmodule AzarSaWeb.Admin.BitacoraLive do
  use AzarSaWeb, :live_view
  alias AzarSa.Bitacora.Logger, as: Bitacora

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(5000, self(), :actualizar)

    registros = Bitacora.obtener_ultimos(100)

    socket =
      socket
      |> assign(:page_title, "Bitácora")
      |> assign(:registros, registros)

    {:ok, socket}
  end

  @impl true
  def handle_info(:actualizar, socket) do
    registros = Bitacora.obtener_ultimos(100)
    {:noreply, assign(socket, :registros, registros)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <header class="bg-indigo-600 shadow">
        <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <.link navigate="/admin" class="text-white hover:text-indigo-200 mr-4">
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                </svg>
              </.link>
              <h1 class="text-3xl font-bold text-white">Bitácora del Sistema</h1>
            </div>
            <span class="text-white text-sm">Actualización automática cada 5s</span>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 border-b border-gray-200 sm:px-6">
            <h3 class="text-lg font-medium text-gray-900">
              Últimos <%= length(@registros) %> registros
            </h3>
          </div>
          
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Fecha</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Hora</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Operación</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Detalle</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Resultado</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for registro <- @registros do %>
                  <tr>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= registro.fecha %></td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= registro.hora %></td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900"><%= registro.tipo %></td>
                    <td class="px-6 py-4 text-sm text-gray-500 max-w-md truncate"><%= registro.detalle %></td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class={"px-2 py-1 text-xs rounded-full #{if registro.resultado == "OK", do: "bg-green-100 text-green-800", else: "bg-red-100 text-red-800"}"}>
                        <%= registro.resultado %>
                      </span>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
