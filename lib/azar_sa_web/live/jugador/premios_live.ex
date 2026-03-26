defmodule AzarSaWeb.Jugador.PremiosLive do
  use AzarSaWeb, :live_view
  alias AzarSa.Servidores.ServidorCentral
  alias AzarSa.Clientes

  @impl true
  def mount(params, _session, socket) do
    cliente_id = params["cliente_id"]

    case cliente_id && Clientes.obtener(cliente_id) do
      {:ok, cliente} ->
        premios = ServidorCentral.premios_cliente(cliente_id)

        socket =
          socket
          |> assign(:page_title, "Mis Premios")
          |> assign(:cliente, cliente)
          |> assign(:premios, premios)

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
            <h1 class="text-3xl font-bold text-white">Mis Premios</h1>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <!-- Total ganado -->
        <div class="bg-gradient-to-r from-green-400 to-green-600 shadow sm:rounded-lg mb-6 p-6 text-white">
          <p class="text-lg">Total ganado</p>
          <p class="text-4xl font-bold">$<%= format_money(calcular_total(@premios)) %></p>
        </div>

        <!-- Lista de premios -->
        <%= if Enum.empty?(@premios) do %>
          <div class="bg-white shadow sm:rounded-lg text-center py-12">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7" />
            </svg>
            <p class="mt-4 text-gray-500">Aún no has ganado ningún premio.</p>
            <p class="text-sm text-gray-400">¡Sigue participando en los sorteos!</p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <%= for premio <- @premios do %>
              <div class="bg-white overflow-hidden shadow rounded-lg border-l-4 border-green-500">
                <div class="p-5">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <svg class="h-10 w-10 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <div class="ml-5">
                      <h3 class="text-lg font-medium text-gray-900"><%= premio.premio_nombre %></h3>
                      <p class="text-sm text-gray-500"><%= premio.sorteo_nombre %></p>
                    </div>
                  </div>
                  <div class="mt-4">
                    <div class="flex justify-between items-center">
                      <span class="text-sm text-gray-500">Número ganador: <strong><%= premio.numero %></strong></span>
                      <span class="text-2xl font-bold text-green-600">$<%= format_money(premio.valor) %></span>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </main>
    </div>
    """
  end

  defp calcular_total(premios) do
    Enum.reduce(premios, 0, fn p, acc -> acc + (p[:valor] || 0) end)
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
