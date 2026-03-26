defmodule AzarSaWeb.Admin.SorteosLive do
  @moduledoc """
  LiveView para gestión de sorteos.
  Lista sorteos y permite crear nuevos.
  """

  use AzarSaWeb, :live_view

  alias AzarSa.Servidores.ServidorCentral

  @impl true
  def mount(_params, _session, socket) do
    sorteos = ServidorCentral.listar_sorteos()

    socket =
      socket
      |> assign(:page_title, "Gestión de Sorteos")
      |> assign(:sorteos, sorteos)
      |> assign(:show_form, false)
      |> assign(:changeset, %{})
      |> assign(:form_data, %{
        "nombre" => "",
        "fecha" => "",
        "valor_billete" => "",
        "cantidad_fracciones" => "1",
        "cantidad_billetes" => ""
      })

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:show_form, true)
    |> assign(:page_title, "Nuevo Sorteo")
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:show_form, false)
    |> assign(:page_title, "Gestión de Sorteos")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <!-- Header -->
      <header class="bg-indigo-600 shadow">
        <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center">
            <div class="flex items-center">
              <.link navigate="/admin" class="text-white hover:text-indigo-200 mr-4">
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                </svg>
              </.link>
              <h1 class="text-3xl font-bold text-white">Gestión de Sorteos</h1>
            </div>
            <.link navigate="/admin/sorteos/nuevo" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-indigo-600 bg-white hover:bg-indigo-50">
              + Nuevo Sorteo
            </.link>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <!-- Formulario de nuevo sorteo -->
        <%= if @show_form do %>
          <div class="bg-white shadow sm:rounded-lg mb-6">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Crear Nuevo Sorteo</h3>
              
              <form phx-submit="crear_sorteo" class="space-y-4">
                <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Nombre del Sorteo</label>
                    <input type="text" name="nombre" value={@form_data["nombre"]} required
                           class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                           placeholder="Ej: Lotería de Medellín" />
                  </div>
                  
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Fecha del Sorteo</label>
                    <input type="date" name="fecha" value={@form_data["fecha"]} required
                           class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                  </div>
                  
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Valor del Billete Completo ($)</label>
                    <input type="number" name="valor_billete" value={@form_data["valor_billete"]} required min="1000"
                           class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                           placeholder="50000" />
                  </div>
                  
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Cantidad de Fracciones</label>
                    <input type="number" name="cantidad_fracciones" value={@form_data["cantidad_fracciones"]} required min="1" max="20"
                           class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                           placeholder="5" />
                  </div>
                  
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Cantidad de Billetes</label>
                    <input type="number" name="cantidad_billetes" value={@form_data["cantidad_billetes"]} required min="1"
                           class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                           placeholder="1000" />
                  </div>
                </div>
                
                <div class="flex justify-end space-x-3">
                  <.link navigate="/admin/sorteos" class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                    Cancelar
                  </.link>
                  <button type="submit" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700">
                    Crear Sorteo
                  </button>
                </div>
              </form>
            </div>
          </div>
        <% end %>

        <!-- Lista de Sorteos -->
        <div class="bg-white shadow overflow-hidden sm:rounded-md">
          <div class="px-4 py-5 border-b border-gray-200 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              Sorteos (<%= length(@sorteos) %>)
            </h3>
          </div>
          
          <%= if Enum.empty?(@sorteos) do %>
            <div class="text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900">No hay sorteos</h3>
              <p class="mt-1 text-sm text-gray-500">Comienza creando un nuevo sorteo.</p>
            </div>
          <% else %>
            <ul role="list" class="divide-y divide-gray-200">
              <%= for sorteo <- @sorteos do %>
                <li>
                  <div class="px-4 py-4 sm:px-6 hover:bg-gray-50">
                    <div class="flex items-center justify-between">
                      <div class="flex-1 min-w-0">
                        <.link navigate={"/admin/sorteos/#{sorteo.id}"} class="text-sm font-medium text-indigo-600 truncate hover:underline">
                          <%= sorteo.nombre %>
                        </.link>
                        <div class="mt-2 flex items-center text-sm text-gray-500">
                          <span class="truncate">
                            Fecha: <%= sorteo.fecha %> | 
                            Valor: $<%= format_money(sorteo.valor_billete) %> | 
                            <%= sorteo.cantidad_fracciones %> fracciones | 
                            <%= sorteo.cantidad_billetes %> billetes
                          </span>
                        </div>
                      </div>
                      <div class="flex items-center space-x-2">
                        <span class={"px-2 py-1 text-xs font-semibold rounded-full #{estado_color(sorteo.estado)}"}>
                          <%= humanize_estado(sorteo.estado) %>
                        </span>
                        
                        <%= if sorteo.estado == :pendiente do %>
                          <button phx-click="eliminar" phx-value-id={sorteo.id} 
                                  data-confirm="¿Estás seguro de eliminar este sorteo?"
                                  class="text-red-600 hover:text-red-900">
                            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                          </button>
                        <% end %>
                      </div>
                    </div>
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

  @impl true
  def handle_event("crear_sorteo", params, socket) do
    attrs = %{
      nombre: params["nombre"],
      fecha: params["fecha"],
      valor_billete: String.to_integer(params["valor_billete"]),
      cantidad_fracciones: String.to_integer(params["cantidad_fracciones"]),
      cantidad_billetes: String.to_integer(params["cantidad_billetes"])
    }

    case ServidorCentral.crear_sorteo(attrs) do
      {:ok, _sorteo} ->
        sorteos = ServidorCentral.listar_sorteos()

        {:noreply,
         socket
         |> assign(:sorteos, sorteos)
         |> assign(:show_form, false)
         |> put_flash(:info, "Sorteo creado exitosamente")
         |> push_navigate(to: "/admin/sorteos")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error al crear sorteo: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("eliminar", %{"id" => id}, socket) do
    case ServidorCentral.eliminar_sorteo(id) do
      {:ok, _} ->
        sorteos = ServidorCentral.listar_sorteos()

        {:noreply,
         socket
         |> assign(:sorteos, sorteos)
         |> put_flash(:info, "Sorteo eliminado")}

      {:error, :tiene_premios_asociados} ->
        {:noreply, put_flash(socket, :error, "No se puede eliminar: tiene premios asociados")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error: #{inspect(reason)}")}
    end
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
