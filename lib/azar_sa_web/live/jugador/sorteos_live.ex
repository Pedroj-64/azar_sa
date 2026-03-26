defmodule AzarSaWeb.Jugador.SorteosLive do
  use AzarSaWeb, :live_view
  alias AzarSa.Servidores.ServidorCentral
  alias AzarSa.Clientes

  @impl true
  def mount(params, _session, socket) do
    cliente_id = params["cliente_id"]

    case cliente_id && Clientes.obtener(cliente_id) do
      {:ok, cliente} ->
        sorteos =
          ServidorCentral.listar_sorteos()
          |> Enum.filter(&(&1.estado == :pendiente))

        socket =
          socket
          |> assign(:page_title, "Sorteos Disponibles")
          |> assign(:cliente, cliente)
          |> assign(:sorteos, sorteos)

        {:ok, socket}

      _ ->
        {:ok, redirect(socket, to: "/login")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <header class="bg-purple-600 shadow">
        <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <div class="flex items-center">
            <.link navigate={"/jugador?cliente_id=#{@cliente.id}"} class="text-white hover:text-purple-200 mr-4">
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </.link>
            <h1 class="text-3xl font-bold text-white">Sorteos Disponibles</h1>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          <%= for sorteo <- @sorteos do %>
            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <h3 class="text-lg font-medium text-gray-900"><%= sorteo.nombre %></h3>
                <dl class="mt-4 space-y-2">
                  <div class="flex justify-between">
                    <dt class="text-sm text-gray-500">Fecha del sorteo</dt>
                    <dd class="text-sm font-medium text-gray-900"><%= sorteo.fecha %></dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-sm text-gray-500">Billete completo</dt>
                    <dd class="text-sm font-medium text-gray-900">$<%= format_money(sorteo.valor_billete) %></dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-sm text-gray-500">Fracción</dt>
                    <dd class="text-sm font-medium text-gray-900">$<%= format_money(sorteo.valor_billete / sorteo.cantidad_fracciones) %></dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-sm text-gray-500">Fracciones</dt>
                    <dd class="text-sm font-medium text-gray-900"><%= sorteo.cantidad_fracciones %></dd>
                  </div>
                </dl>
              </div>
              <div class="bg-gray-50 px-5 py-3">
                <.link navigate={"/jugador/sorteos/#{sorteo.id}/comprar?cliente_id=#{@cliente.id}"} 
                       class="w-full inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700">
                  Comprar Billete
                </.link>
              </div>
            </div>
          <% end %>
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
