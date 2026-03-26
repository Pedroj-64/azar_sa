defmodule AzarSaWeb.Jugador.SorteoLive do
  use AzarSaWeb, :live_view
  alias AzarSa.Servidores.ServidorCentral
  alias AzarSa.Clientes

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    cliente_id = params["cliente_id"]

    with {:ok, cliente} <- Clientes.obtener(cliente_id),
         {:ok, sorteo} <- ServidorCentral.obtener_sorteo(id) do
      socket =
        socket
        |> assign(:page_title, sorteo.nombre)
        |> assign(:cliente, cliente)
        |> assign(:sorteo, sorteo)

      {:ok, socket}
    else
      _ -> {:ok, redirect(socket, to: "/login")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <header class="bg-purple-600 shadow">
        <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <div class="flex items-center">
            <.link navigate={"/jugador/sorteos?cliente_id=#{@cliente.id}"} class="text-white hover:text-purple-200 mr-4">
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </.link>
            <h1 class="text-3xl font-bold text-white"><%= @sorteo.nombre %></h1>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="bg-white shadow sm:rounded-lg p-6">
          <dl class="grid grid-cols-2 gap-4">
            <div>
              <dt class="text-sm font-medium text-gray-500">Fecha</dt>
              <dd class="mt-1 text-lg text-gray-900"><%= @sorteo.fecha %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Valor del Billete</dt>
              <dd class="mt-1 text-lg text-gray-900">$<%= format_money(@sorteo.valor_billete) %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Fracciones</dt>
              <dd class="mt-1 text-lg text-gray-900"><%= @sorteo.cantidad_fracciones %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Total Billetes</dt>
              <dd class="mt-1 text-lg text-gray-900"><%= @sorteo.cantidad_billetes %></dd>
            </div>
          </dl>

          <%= if @sorteo.estado == :pendiente do %>
            <div class="mt-6">
              <.link navigate={"/jugador/sorteos/#{@sorteo.id}/comprar?cliente_id=#{@cliente.id}"} 
                     class="w-full inline-flex justify-center items-center px-4 py-3 border border-transparent text-base font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700">
                Comprar Billete
              </.link>
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
