defmodule AzarSaWeb.Jugador.NotificacionesLive do
  use AzarSaWeb, :live_view
  alias AzarSa.Clientes

  @impl true
  def mount(params, _session, socket) do
    cliente_id = params["cliente_id"]

    case cliente_id && Clientes.obtener(cliente_id) do
      {:ok, cliente} ->
        if connected?(socket) do
          AzarSa.Notificaciones.Servidor.suscribir(cliente_id)
        end

        socket =
          socket
          |> assign(:page_title, "Notificaciones")
          |> assign(:cliente, cliente)

        {:ok, socket}

      _ ->
        {:ok, redirect(socket, to: "/login")}
    end
  end

  @impl true
  def handle_info({:notificacion, _notif}, socket) do
    {:ok, cliente} = Clientes.obtener(socket.assigns.cliente.id)
    {:noreply, assign(socket, :cliente, cliente)}
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
            <h1 class="text-3xl font-bold text-white">Notificaciones</h1>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <%= if Enum.empty?(@cliente.notificaciones) do %>
          <div class="bg-white shadow sm:rounded-lg text-center py-12">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
            <p class="mt-4 text-gray-500">No tienes notificaciones.</p>
          </div>
        <% else %>
          <div class="bg-white shadow overflow-hidden sm:rounded-md">
            <ul role="list" class="divide-y divide-gray-200">
              <%= for notif <- @cliente.notificaciones do %>
                <% leida = notif["leida"] || notif[:leida] || false %>
                <li class={"px-4 py-4 sm:px-6 #{if not leida, do: "bg-purple-50"}"}>
                  <div class="flex items-start">
                    <div class="flex-shrink-0">
                      <%= if not leida do %>
                        <span class="inline-block h-2 w-2 rounded-full bg-purple-600"></span>
                      <% end %>
                    </div>
                    <div class="ml-3 flex-1">
                      <p class="text-sm text-gray-900 whitespace-pre-line"><%= notif["mensaje"] || notif[:mensaje] %></p>
                      <p class="mt-1 text-xs text-gray-500"><%= notif["fecha"] || notif[:fecha] %></p>
                    </div>
                    <%= if not leida do %>
                      <button phx-click="marcar_leida" phx-value-id={notif["id"] || notif[:id]}
                              class="text-xs text-purple-600 hover:underline">
                        Marcar como leída
                      </button>
                    <% end %>
                  </div>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("marcar_leida", %{"id" => notif_id}, socket) do
    case Clientes.marcar_notificacion_leida(socket.assigns.cliente.id, notif_id) do
      {:ok, cliente} ->
        {:noreply, assign(socket, :cliente, cliente)}

      _ ->
        {:noreply, socket}
    end
  end
end
