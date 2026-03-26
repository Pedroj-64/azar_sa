defmodule AzarSaWeb.Jugador.CompraLive do
  use AzarSaWeb, :live_view
  alias AzarSa.Servidores.ServidorCentral
  alias AzarSa.Clientes

  @impl true
  def mount(%{"id" => sorteo_id} = params, _session, socket) do
    cliente_id = params["cliente_id"]

    with {:ok, cliente} <- Clientes.obtener(cliente_id),
         {:ok, sorteo} <- ServidorCentral.obtener_sorteo(sorteo_id),
         {:ok, disponibilidad} <- ServidorCentral.numeros_disponibles(sorteo_id) do
      socket =
        socket
        |> assign(:page_title, "Comprar - #{sorteo.nombre}")
        |> assign(:cliente, cliente)
        |> assign(:sorteo, sorteo)
        |> assign(:disponibilidad, disponibilidad)
        |> assign(:numero_seleccionado, nil)
        |> assign(:tipo_compra, "billete_completo")
        |> assign(:fracciones_seleccionadas, [])

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
            <h1 class="text-3xl font-bold text-white">Comprar - <%= @sorteo.nombre %></h1>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
          <!-- Selección de número -->
          <div class="lg:col-span-2 bg-white shadow sm:rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg font-medium text-gray-900 mb-4">Selecciona un número</h3>
              
              <div class="grid grid-cols-10 gap-2 max-h-96 overflow-y-auto">
                <%= for num <- @disponibilidad do %>
                  <%= if num.disponible do %>
                    <button 
                      phx-click="seleccionar_numero" 
                      phx-value-numero={num.numero}
                      class={"w-full py-2 text-xs rounded #{if @numero_seleccionado == num.numero, do: "bg-purple-600 text-white", else: "bg-gray-100 hover:bg-purple-100"}"}>
                      <%= num.numero %>
                    </button>
                  <% else %>
                    <button disabled class="w-full py-2 text-xs rounded bg-red-100 text-red-400 cursor-not-allowed">
                      <%= num.numero %>
                    </button>
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Panel de compra -->
          <div class="bg-white shadow sm:rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg font-medium text-gray-900 mb-4">Detalles de Compra</h3>
              
              <%= if @numero_seleccionado do %>
                <% num_info = Enum.find(@disponibilidad, & &1.numero == @numero_seleccionado) %>
                
                <div class="mb-4">
                  <p class="text-sm text-gray-500">Número seleccionado:</p>
                  <p class="text-3xl font-bold text-purple-600"><%= @numero_seleccionado %></p>
                </div>

                <div class="mb-4">
                  <label class="block text-sm font-medium text-gray-700 mb-2">Tipo de compra</label>
                  <select phx-change="cambiar_tipo" name="tipo" class="block w-full border-gray-300 rounded-md shadow-sm">
                    <%= if num_info && num_info.billete_completo do %>
                      <option value="billete_completo" selected={@tipo_compra == "billete_completo"}>
                        Billete Completo - $<%= format_money(@sorteo.valor_billete) %>
                      </option>
                    <% end %>
                    <option value="fracciones" selected={@tipo_compra == "fracciones"}>
                      Fracciones - $<%= format_money(@sorteo.valor_billete / @sorteo.cantidad_fracciones) %> c/u
                    </option>
                  </select>
                </div>

                <%= if @tipo_compra == "fracciones" and num_info do %>
                  <div class="mb-4">
                    <label class="block text-sm font-medium text-gray-700 mb-2">Selecciona fracciones</label>
                    <div class="grid grid-cols-5 gap-2">
                      <%= for f <- num_info.fracciones_disponibles do %>
                        <button 
                          phx-click="toggle_fraccion" 
                          phx-value-fraccion={f}
                          class={"w-full py-2 text-sm rounded #{if f in @fracciones_seleccionadas, do: "bg-purple-600 text-white", else: "bg-gray-100 hover:bg-purple-100"}"}>
                          <%= f %>
                        </button>
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <div class="border-t pt-4">
                  <div class="flex justify-between mb-2">
                    <span class="text-gray-500">Total a pagar:</span>
                    <span class="font-bold text-lg">$<%= format_money(calcular_total(assigns)) %></span>
                  </div>
                  
                  <button 
                    phx-click="confirmar_compra"
                    disabled={not puede_comprar?(assigns)}
                    class={"w-full py-3 rounded-md text-white font-medium #{if puede_comprar?(assigns), do: "bg-purple-600 hover:bg-purple-700", else: "bg-gray-400 cursor-not-allowed"}"}>
                    Confirmar Compra
                  </button>
                </div>
              <% else %>
                <p class="text-gray-500 text-center py-8">
                  Selecciona un número disponible para continuar
                </p>
              <% end %>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("seleccionar_numero", %{"numero" => numero}, socket) do
    numero = String.to_integer(numero)

    {:noreply,
     socket
     |> assign(:numero_seleccionado, numero)
     |> assign(:fracciones_seleccionadas, [])}
  end

  @impl true
  def handle_event("cambiar_tipo", %{"tipo" => tipo}, socket) do
    {:noreply,
     socket
     |> assign(:tipo_compra, tipo)
     |> assign(:fracciones_seleccionadas, [])}
  end

  @impl true
  def handle_event("toggle_fraccion", %{"fraccion" => fraccion}, socket) do
    fraccion = String.to_integer(fraccion)
    fracciones = socket.assigns.fracciones_seleccionadas

    nuevas_fracciones =
      if fraccion in fracciones do
        List.delete(fracciones, fraccion)
      else
        [fraccion | fracciones]
      end

    {:noreply, assign(socket, :fracciones_seleccionadas, nuevas_fracciones)}
  end

  @impl true
  def handle_event("confirmar_compra", _params, socket) do
    %{cliente: cliente, sorteo: sorteo, numero_seleccionado: numero, tipo_compra: tipo} =
      socket.assigns

    resultado =
      case tipo do
        "billete_completo" ->
          ServidorCentral.comprar_billete(cliente.id, sorteo.id, numero)

        "fracciones" ->
          ServidorCentral.comprar_fracciones(
            cliente.id,
            sorteo.id,
            numero,
            socket.assigns.fracciones_seleccionadas
          )
      end

    case resultado do
      {:ok, _compra} ->
        {:noreply,
         socket
         |> put_flash(:info, "Compra realizada exitosamente")
         |> redirect(to: "/jugador/compras?cliente_id=#{cliente.id}")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error: #{inspect(reason)}")}
    end
  end

  defp calcular_total(assigns) do
    case assigns.tipo_compra do
      "billete_completo" ->
        assigns.sorteo.valor_billete

      "fracciones" ->
        valor_fraccion = assigns.sorteo.valor_billete / assigns.sorteo.cantidad_fracciones
        valor_fraccion * length(assigns.fracciones_seleccionadas)
    end
  end

  defp puede_comprar?(assigns) do
    assigns.numero_seleccionado != nil and
      (assigns.tipo_compra == "billete_completo" or length(assigns.fracciones_seleccionadas) > 0)
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
