defmodule AzarSaWeb.Admin.DashboardLive do
  @moduledoc """
  Dashboard principal del panel de administración.
  Muestra resumen de sorteos, ingresos y estadísticas.
  """

  use AzarSaWeb, :live_view

  alias AzarSa.Servidores.ServidorCentral

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Suscribirse a actualizaciones
      Phoenix.PubSub.subscribe(AzarSa.PubSub, "admin:updates")
    end

    socket =
      socket
      |> assign(:page_title, "Dashboard - Administración")
      |> cargar_estadisticas()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <!-- Header -->
      <header class="bg-indigo-600 shadow">
        <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center">
            <h1 class="text-3xl font-bold text-white">
              Panel de Administración - Azar S.A.
            </h1>
            <nav class="flex space-x-4">
              <.link navigate="/admin/sorteos" class="text-white hover:text-indigo-200">Sorteos</.link>
              <.link navigate="/admin/premios" class="text-white hover:text-indigo-200">Premios</.link>
              <.link navigate="/admin/clientes" class="text-white hover:text-indigo-200">Clientes</.link>
              <.link navigate="/admin/balance" class="text-white hover:text-indigo-200">Balance</.link>
              <.link navigate="/admin/bitacora" class="text-white hover:text-indigo-200">Bitácora</.link>
              <.link navigate="/admin/sistema" class="text-white hover:text-indigo-200">Sistema</.link>
            </nav>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <!-- Estadísticas -->
        <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          <!-- Total Sorteos -->
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg class="h-6 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Total Sorteos</dt>
                    <dd class="text-lg font-medium text-gray-900"><%= @total_sorteos %></dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <!-- Sorteos Pendientes -->
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg class="h-6 w-6 text-yellow-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Sorteos Pendientes</dt>
                    <dd class="text-lg font-medium text-gray-900"><%= @sorteos_pendientes %></dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <!-- Total Ingresos -->
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg class="h-6 w-6 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Total Ingresos</dt>
                    <dd class="text-lg font-medium text-gray-900">$<%= format_money(@total_ingresos) %></dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <!-- Balance -->
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <svg class={"h-6 w-6 #{if @balance >= 0, do: "text-green-400", else: "text-red-400"}"} fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Balance Total</dt>
                    <dd class={"text-lg font-medium #{if @balance >= 0, do: "text-green-600", else: "text-red-600"}"}>
                      $<%= format_money(@balance) %>
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Últimos Sorteos -->
        <div class="mt-8">
          <div class="flex items-center justify-between">
            <h2 class="text-lg leading-6 font-medium text-gray-900">Últimos Sorteos</h2>
            <.link navigate="/admin/sorteos/nuevo" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700">
              Nuevo Sorteo
            </.link>
          </div>
          
          <div class="mt-4 bg-white shadow overflow-hidden sm:rounded-md">
            <ul role="list" class="divide-y divide-gray-200">
              <%= for sorteo <- @ultimos_sorteos do %>
                <li>
                  <.link navigate={"/admin/sorteos/#{sorteo.id}"} class="block hover:bg-gray-50">
                    <div class="px-4 py-4 sm:px-6">
                      <div class="flex items-center justify-between">
                        <p class="text-sm font-medium text-indigo-600 truncate"><%= sorteo.nombre %></p>
                        <div class="ml-2 flex-shrink-0 flex">
                          <p class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{estado_color(sorteo.estado)}"}>
                            <%= humanize_estado(sorteo.estado) %>
                          </p>
                        </div>
                      </div>
                      <div class="mt-2 sm:flex sm:justify-between">
                        <div class="sm:flex">
                          <p class="flex items-center text-sm text-gray-500">
                            Fecha: <%= sorteo.fecha %>
                          </p>
                          <p class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0 sm:ml-6">
                            Valor: $<%= format_money(sorteo.valor_billete) %>
                          </p>
                        </div>
                        <div class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                          <p><%= sorteo.cantidad_billetes %> billetes</p>
                        </div>
                      </div>
                    </div>
                  </.link>
                </li>
              <% end %>
            </ul>
          </div>
        </div>

        <!-- Fecha del Sistema -->
        <div class="mt-8 bg-yellow-50 border-l-4 border-yellow-400 p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm text-yellow-700">
                Fecha del Sistema: <strong><%= @fecha_sistema %></strong>
                <.link navigate="/admin/sistema" class="font-medium underline text-yellow-700 hover:text-yellow-600 ml-2">
                  Modificar
                </.link>
              </p>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  # ============================================================================
  # Funciones Privadas
  # ============================================================================

  defp cargar_estadisticas(socket) do
    sorteos = ServidorCentral.listar_sorteos()

    {:ok, balance_data} = ServidorCentral.balance_sorteos_pasados()
    fecha_sistema = AzarSa.Sistema.Fecha.fecha_actual()

    socket
    |> assign(:total_sorteos, length(sorteos))
    |> assign(:sorteos_pendientes, Enum.count(sorteos, &(&1.estado == :pendiente)))
    |> assign(:total_ingresos, balance_data.total_ingresos)
    |> assign(:balance, balance_data.balance_total)
    |> assign(:ultimos_sorteos, Enum.take(sorteos, 5))
    |> assign(:fecha_sistema, fecha_sistema)
  end

  defp format_money(amount) when is_number(amount) do
    amount
    |> round()
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  defp format_money(_), do: "0"

  defp estado_color(:pendiente), do: "bg-yellow-100 text-yellow-800"
  defp estado_color(:realizado), do: "bg-green-100 text-green-800"
  defp estado_color(:cancelado), do: "bg-red-100 text-red-800"
  defp estado_color(_), do: "bg-gray-100 text-gray-800"

  defp humanize_estado(:pendiente), do: "Pendiente"
  defp humanize_estado(:realizado), do: "Realizado"
  defp humanize_estado(:cancelado), do: "Cancelado"
  defp humanize_estado(estado), do: to_string(estado)
end
