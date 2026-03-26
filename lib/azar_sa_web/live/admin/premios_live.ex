defmodule AzarSaWeb.Admin.PremiosLive do
  use AzarSaWeb, :live_view
  alias AzarSa.Servidores.ServidorCentral

  @impl true
  def mount(_params, _session, socket) do
    sorteos = ServidorCentral.listar_sorteos()
    premios = ServidorCentral.listar_premios()

    socket =
      socket
      |> assign(:page_title, "Gestión de Premios")
      |> assign(:sorteos, sorteos)
      |> assign(:premios, premios)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

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
            <h1 class="text-3xl font-bold text-white">Gestión de Premios</h1>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <!-- Premios agrupados por sorteo -->
        <%= for sorteo <- @sorteos do %>
          <div class="bg-white shadow sm:rounded-lg mb-6">
            <div class="px-4 py-5 sm:p-6">
              <div class="flex justify-between items-center mb-4">
                <div>
                  <h3 class="text-lg font-medium text-gray-900"><%= sorteo.nombre %></h3>
                  <p class="text-sm text-gray-500">Fecha: <%= sorteo.fecha %></p>
                </div>
                <span class={"px-2 py-1 text-xs rounded-full #{estado_color(sorteo.estado)}"}>
                  <%= humanize_estado(sorteo.estado) %>
                </span>
              </div>

              <%= if Enum.empty?(sorteo.premios) do %>
                <p class="text-gray-500 text-sm">Sin premios configurados</p>
              <% else %>
                <ul class="divide-y divide-gray-200">
                  <%= for premio_id <- sorteo.premios do %>
                    <% premio = Enum.find(@premios, & &1.id == premio_id) %>
                    <%= if premio do %>
                      <li class="py-3 flex justify-between items-center">
                        <div>
                          <span class="font-medium"><%= premio.nombre %></span>
                          <span class="text-green-600 ml-2">$<%= format_money(premio.valor) %></span>
                        </div>
                        <%= if premio.numero_ganador do %>
                          <span class="text-sm bg-green-100 text-green-800 px-2 py-1 rounded">
                            Ganador: #<%= premio.numero_ganador %>
                          </span>
                        <% end %>
                      </li>
                    <% end %>
                  <% end %>
                </ul>
              <% end %>

              <%= if sorteo.estado == :pendiente do %>
                <.link navigate={"/admin/sorteos/#{sorteo.id}"} class="mt-3 inline-block text-sm text-indigo-600 hover:underline">
                  + Agregar premio
                </.link>
              <% end %>
            </div>
          </div>
        <% end %>
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

  defp estado_color(:pendiente), do: "bg-yellow-100 text-yellow-800"
  defp estado_color(:realizado), do: "bg-green-100 text-green-800"
  defp estado_color(_), do: "bg-gray-100 text-gray-800"

  defp humanize_estado(:pendiente), do: "Pendiente"
  defp humanize_estado(:realizado), do: "Realizado"
  defp humanize_estado(estado), do: to_string(estado)
end
