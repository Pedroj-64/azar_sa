defmodule AzarSaWeb.Admin.BalanceLive do
  use AzarSaWeb, :live_view
  alias AzarSa.Servidores.ServidorCentral

  @impl true
  def mount(_params, _session, socket) do
    {:ok, balance} = ServidorCentral.balance_sorteos_pasados()

    socket =
      socket
      |> assign(:page_title, "Balance General")
      |> assign(:balance, balance)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <header class="bg-indigo-600 shadow">
        <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <div class="flex items-center">
            <.link navigate="/admin" class="text-white hover:text-indigo-200 mr-4">
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </.link>
            <h1 class="text-3xl font-bold text-white">Balance de Sorteos</h1>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <!-- Resumen Total -->
        <div class="grid grid-cols-1 gap-5 sm:grid-cols-3 mb-6">
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <dt class="text-sm font-medium text-gray-500">Total Ingresos</dt>
              <dd class="mt-1 text-2xl font-semibold text-green-600">$<%= format_money(@balance.total_ingresos) %></dd>
            </div>
          </div>
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <dt class="text-sm font-medium text-gray-500">Premios Entregados</dt>
              <dd class="mt-1 text-2xl font-semibold text-red-600">$<%= format_money(@balance.total_premios_entregados) %></dd>
            </div>
          </div>
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <dt class="text-sm font-medium text-gray-500">Balance Total</dt>
              <dd class={"mt-1 text-2xl font-semibold #{if @balance.balance_total >= 0, do: "text-green-600", else: "text-red-600"}"}>
                $<%= format_money(@balance.balance_total) %>
              </dd>
            </div>
          </div>
        </div>

        <!-- Balance por Sorteo -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 border-b border-gray-200 sm:px-6">
            <h3 class="text-lg font-medium text-gray-900">Balance por Sorteo</h3>
          </div>
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Sorteo</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Ingresos</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Premios</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Ganancia</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for item <- @balance.sorteos do %>
                <tr>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    <%= item.sorteo.nombre %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-right text-green-600">
                    $<%= format_money(item.ingresos) %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-right text-red-600">
                    $<%= format_money(item.premios_entregados) %>
                  </td>
                  <td class={"px-6 py-4 whitespace-nowrap text-sm text-right font-semibold #{if item.ganancia >= 0, do: "text-green-600", else: "text-red-600"}"}>
                    $<%= format_money(item.ganancia) %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </main>
    </div>
    """
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
end
