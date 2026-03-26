defmodule AzarSaWeb.Jugador.DashboardLive do
  use AzarSaWeb, :live_view
  alias AzarSa.Servidores.ServidorCentral
  alias AzarSa.Clientes

  @impl true
  def mount(params, session, socket) do
    cliente_id = params["cliente_id"] || session["jugador_id"]

    case cliente_id && Clientes.obtener(cliente_id) do
      {:ok, cliente} ->
        sorteos =
          ServidorCentral.listar_sorteos()
          |> Enum.filter(&(&1.estado == :pendiente))

        {:ok, balance} = ServidorCentral.balance_cliente(cliente_id)

        if connected?(socket) do
          AzarSa.Notificaciones.Servidor.suscribir(cliente_id)
        end

        socket =
          socket
          |> assign(:page_title, "Mi Panel")
          |> assign(:cliente, cliente)
          |> assign(:sorteos_disponibles, sorteos)
          |> assign(:balance, balance)
          |> assign(:notificaciones_sin_leer, contar_sin_leer(cliente.notificaciones))

        {:ok, socket}

      _ ->
        {:ok, redirect(socket, to: "/login")}
    end
  end

  @impl true
  def handle_info({:notificacion, _notif}, socket) do
    # Recargar notificaciones
    {:ok, cliente} = Clientes.obtener(socket.assigns.cliente.id)

    {:noreply,
     socket
     |> assign(:cliente, cliente)
     |> assign(:notificaciones_sin_leer, contar_sin_leer(cliente.notificaciones))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <!-- Header -->
      <header class="bg-purple-600 shadow">
        <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center">
            <h1 class="text-3xl font-bold text-white">
              Hola, <%= @cliente.nombre %>
            </h1>
            <nav class="flex items-center space-x-4">
              <.link navigate={"/jugador/sorteos?cliente_id=#{@cliente.id}"} class="text-white hover:text-purple-200">Sorteos</.link>
              <.link navigate={"/jugador/compras?cliente_id=#{@cliente.id}"} class="text-white hover:text-purple-200">Mis Compras</.link>
              <.link navigate={"/jugador/premios?cliente_id=#{@cliente.id}"} class="text-white hover:text-purple-200">Mis Premios</.link>
              <.link navigate={"/jugador/notificaciones?cliente_id=#{@cliente.id}"} class="relative text-white hover:text-purple-200">
                Notificaciones
                <%= if @notificaciones_sin_leer > 0 do %>
                  <span class="absolute -top-2 -right-2 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                    <%= @notificaciones_sin_leer %>
                  </span>
                <% end %>
              </.link>
              <.link href="/logout" class="text-white hover:text-purple-200">Salir</.link>
            </nav>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <!-- Balance -->
        <div class="grid grid-cols-1 gap-5 sm:grid-cols-3 mb-8">
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <dt class="text-sm font-medium text-gray-500">Total Gastado</dt>
              <dd class="mt-1 text-2xl font-semibold text-red-600">$<%= format_money(@balance.total_gastado) %></dd>
            </div>
          </div>
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <dt class="text-sm font-medium text-gray-500">Total Ganado</dt>
              <dd class="mt-1 text-2xl font-semibold text-green-600">$<%= format_money(@balance.total_ganado) %></dd>
            </div>
          </div>
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
              <dt class="text-sm font-medium text-gray-500">Balance</dt>
              <dd class={"mt-1 text-2xl font-semibold #{if @balance.balance >= 0, do: "text-green-600", else: "text-red-600"}"}>
                $<%= format_money(@balance.balance) %>
              </dd>
            </div>
          </div>
        </div>

        <!-- Sorteos Disponibles -->
        <div class="bg-white shadow sm:rounded-lg">
          <div class="px-4 py-5 border-b border-gray-200 sm:px-6">
            <h3 class="text-lg font-medium text-gray-900">Sorteos Disponibles</h3>
          </div>
          
          <%= if Enum.empty?(@sorteos_disponibles) do %>
            <div class="text-center py-12">
              <p class="text-gray-500">No hay sorteos disponibles en este momento.</p>
            </div>
          <% else %>
            <ul role="list" class="divide-y divide-gray-200">
              <%= for sorteo <- @sorteos_disponibles do %>
                <li class="px-4 py-4 sm:px-6 hover:bg-gray-50">
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-purple-600"><%= sorteo.nombre %></p>
                      <p class="text-sm text-gray-500">
                        Fecha: <%= sorteo.fecha %> | Billete: $<%= format_money(sorteo.valor_billete) %>
                      </p>
                    </div>
                    <.link navigate={"/jugador/sorteos/#{sorteo.id}/comprar?cliente_id=#{@cliente.id}"} 
                           class="px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 text-sm">
                      Comprar
                    </.link>
                  </div>
                </li>
              <% end %>
            </ul>
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

  defp contar_sin_leer(notificaciones) do
    Enum.count(notificaciones, fn n ->
      not (n["leida"] || n[:leida] || false)
    end)
  end
end
