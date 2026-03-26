defmodule AzarSaWeb.Admin.ClientesLive do
  use AzarSaWeb, :live_view
  alias AzarSa.Clientes

  @impl true
  def mount(_params, _session, socket) do
    clientes = Clientes.listar()

    socket =
      socket
      |> assign(:page_title, "Clientes")
      |> assign(:clientes, clientes)

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
            <h1 class="text-3xl font-bold text-white">Clientes Registrados</h1>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="bg-white shadow overflow-hidden sm:rounded-md">
          <ul role="list" class="divide-y divide-gray-200">
            <%= for cliente <- @clientes do %>
              <li class="px-4 py-4 sm:px-6">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="text-sm font-medium text-indigo-600"><%= cliente.nombre %></p>
                    <p class="text-sm text-gray-500">Documento: <%= cliente.documento %></p>
                  </div>
                  <div class="text-right text-xs text-gray-400">
                    <p>Registrado: <%= cliente.created_at %></p>
                    <p>Notificaciones: <%= length(cliente.notificaciones) %></p>
                  </div>
                </div>
              </li>
            <% end %>
          </ul>
        </div>
      </main>
    </div>
    """
  end
end
