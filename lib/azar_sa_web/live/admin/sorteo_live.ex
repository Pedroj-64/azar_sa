defmodule AzarSaWeb.Admin.SorteoLive do
  @moduledoc """
  LiveView para ver y gestionar un sorteo individual.
  Muestra detalles, premios, clientes y permite ejecutar el sorteo.
  """

  use AzarSaWeb, :live_view

  alias AzarSa.Servidores.ServidorCentral

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case ServidorCentral.obtener_sorteo(id) do
      {:ok, sorteo} ->
        {:ok, clientes} = ServidorCentral.clientes_sorteo(id)
        {:ok, ingresos} = ServidorCentral.ingresos_sorteo(id)

        socket =
          socket
          |> assign(:page_title, sorteo.nombre)
          |> assign(:sorteo, sorteo)
          |> assign(:clientes, clientes)
          |> assign(:ingresos, ingresos)
          |> assign(:show_premio_form, false)
          |> assign(:premio_form, %{"nombre" => "", "valor" => ""})

        {:ok, socket}

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Sorteo no encontrado")
         |> push_navigate(to: "/admin/sorteos")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
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
              <.link navigate="/admin/sorteos" class="text-white hover:text-indigo-200 mr-4">
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                </svg>
              </.link>
              <h1 class="text-3xl font-bold text-white"><%= @sorteo.nombre %></h1>
            </div>
            <span class={"px-3 py-1 text-sm font-semibold rounded-full #{estado_color(@sorteo.estado)}"}>
              <%= humanize_estado(@sorteo.estado) %>
            </span>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <!-- Información del Sorteo -->
          <div class="bg-white shadow sm:rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Información del Sorteo</h3>
              
              <dl class="grid grid-cols-2 gap-4">
                <div>
                  <dt class="text-sm font-medium text-gray-500">Fecha</dt>
                  <dd class="mt-1 text-sm text-gray-900"><%= @sorteo.fecha %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Valor del Billete</dt>
                  <dd class="mt-1 text-sm text-gray-900">$<%= format_money(@sorteo.valor_billete) %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Fracciones por Billete</dt>
                  <dd class="mt-1 text-sm text-gray-900"><%= @sorteo.cantidad_fracciones %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Valor por Fracción</dt>
                  <dd class="mt-1 text-sm text-gray-900">$<%= format_money(@sorteo.valor_billete / @sorteo.cantidad_fracciones) %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Total de Billetes</dt>
                  <dd class="mt-1 text-sm text-gray-900"><%= @sorteo.cantidad_billetes %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Ingresos Actuales</dt>
                  <dd class="mt-1 text-sm text-green-600 font-semibold">$<%= format_money(@ingresos.total) %></dd>
                </div>
              </dl>

              <%= if @sorteo.estado == :pendiente do %>
                <div class="mt-6 flex space-x-3">
                  <button phx-click="ejecutar_sorteo" 
                          data-confirm="¿Ejecutar el sorteo ahora? Se asignarán los números ganadores."
                          class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-green-600 hover:bg-green-700">
                    Ejecutar Sorteo
                  </button>
                </div>
              <% end %>

              <!-- Números Ganadores (si ya se realizó) -->
              <%= if @sorteo.estado == :realizado and length(@sorteo.numeros_ganadores) > 0 do %>
                <div class="mt-6 border-t pt-4">
                  <h4 class="text-md font-medium text-gray-900 mb-3">Números Ganadores</h4>
                  <div class="space-y-2">
                    <%= for ganador <- @sorteo.numeros_ganadores do %>
                      <div class="flex justify-between items-center bg-green-50 p-3 rounded-md">
                        <div>
                          <span class="font-semibold text-green-800"><%= ganador.premio_nombre %></span>
                          <span class="text-gray-600 ml-2">Número: <strong><%= ganador.numero %></strong></span>
                        </div>
                        <span class="text-green-600 font-bold">$<%= format_money(ganador.valor) %></span>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Premios -->
          <div class="bg-white shadow sm:rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <div class="flex justify-between items-center mb-4">
                <h3 class="text-lg leading-6 font-medium text-gray-900">Premios</h3>
                <%= if @sorteo.estado == :pendiente do %>
                  <button phx-click="toggle_premio_form" class="text-sm text-indigo-600 hover:text-indigo-800">
                    + Agregar Premio
                  </button>
                <% end %>
              </div>

              <!-- Formulario de nuevo premio -->
              <%= if @show_premio_form do %>
                <form phx-submit="crear_premio" class="mb-4 p-4 bg-gray-50 rounded-md">
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700">Nombre</label>
                      <input type="text" name="nombre" value={@premio_form["nombre"]} required
                             class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                             placeholder="Premio Mayor" />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700">Valor ($)</label>
                      <input type="number" name="valor" value={@premio_form["valor"]} required min="1"
                             class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                             placeholder="500000000" />
                    </div>
                  </div>
                  <div class="mt-3 flex justify-end space-x-2">
                    <button type="button" phx-click="toggle_premio_form" class="text-sm text-gray-600">Cancelar</button>
                    <button type="submit" class="px-3 py-1 bg-indigo-600 text-white rounded-md text-sm">Guardar</button>
                  </div>
                </form>
              <% end %>

              <!-- Lista de premios -->
              <%= if Enum.empty?(@sorteo.premios) do %>
                <p class="text-gray-500 text-sm">No hay premios configurados.</p>
              <% else %>
                <ul class="divide-y divide-gray-200">
                  <%= for premio_id <- @sorteo.premios do %>
                    <li class="py-3 flex justify-between items-center">
                      <span class="text-sm text-gray-900"><%= premio_id %></span>
                    </li>
                  <% end %>
                </ul>
              <% end %>
            </div>
          </div>

          <!-- Clientes del Sorteo -->
          <div class="bg-white shadow sm:rounded-lg lg:col-span-2">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                Clientes del Sorteo (<%= @clientes.total %>)
              </h3>

              <%= if @clientes.total == 0 do %>
                <p class="text-gray-500 text-sm">No hay clientes registrados en este sorteo.</p>
              <% else %>
                <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                  <!-- Compradores de Billete Completo -->
                  <div>
                    <h4 class="text-md font-medium text-gray-700 mb-2">
                      Billete Completo (<%= length(@clientes.compradores_billete_completo) %>)
                    </h4>
                    <ul class="divide-y divide-gray-200 border rounded-md">
                      <%= for cliente <- @clientes.compradores_billete_completo do %>
                        <li class="px-3 py-2 text-sm">
                          <span class="font-medium"><%= cliente.nombre %></span>
                          <span class="text-gray-500 text-xs ml-2">Doc: <%= cliente.documento %></span>
                        </li>
                      <% end %>
                    </ul>
                  </div>

                  <!-- Compradores de Fracciones -->
                  <div>
                    <h4 class="text-md font-medium text-gray-700 mb-2">
                      Fracciones (<%= length(@clientes.compradores_fracciones) %>)
                    </h4>
                    <ul class="divide-y divide-gray-200 border rounded-md">
                      <%= for cliente <- @clientes.compradores_fracciones do %>
                        <li class="px-3 py-2 text-sm">
                          <span class="font-medium"><%= cliente.nombre %></span>
                          <span class="text-gray-500 text-xs ml-2">Doc: <%= cliente.documento %></span>
                        </li>
                      <% end %>
                    </ul>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_premio_form", _params, socket) do
    {:noreply, assign(socket, :show_premio_form, !socket.assigns.show_premio_form)}
  end

  @impl true
  def handle_event("crear_premio", params, socket) do
    premio_params = %{
      nombre: params["nombre"],
      valor: String.to_integer(params["valor"])
    }

    case ServidorCentral.crear_premio(socket.assigns.sorteo.id, premio_params) do
      {:ok, _premio} ->
        {:ok, sorteo} = ServidorCentral.obtener_sorteo(socket.assigns.sorteo.id)

        {:noreply,
         socket
         |> assign(:sorteo, sorteo)
         |> assign(:show_premio_form, false)
         |> put_flash(:info, "Premio creado exitosamente")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("ejecutar_sorteo", _params, socket) do
    case ServidorCentral.ejecutar_sorteo(socket.assigns.sorteo.id) do
      {:ok, sorteo} ->
        {:noreply,
         socket
         |> assign(:sorteo, sorteo)
         |> put_flash(:info, "Sorteo ejecutado. Se enviaron notificaciones a los ganadores.")}

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
