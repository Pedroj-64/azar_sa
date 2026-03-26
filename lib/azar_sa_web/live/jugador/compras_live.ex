defmodule AzarSaWeb.Jugador.ComprasLive do
  use AzarSaWeb, :live_view
  alias AzarSa.Servidores.ServidorCentral
  alias AzarSa.Clientes

  @impl true
  def mount(params, _session, socket) do
    cliente_id = params["cliente_id"]

    case cliente_id && Clientes.obtener(cliente_id) do
      {:ok, cliente} ->
        compras = ServidorCentral.historial_compras(cliente_id)

        socket =
          socket
          |> assign(:page_title, "Mis Compras")
          |> assign(:cliente, cliente)
          |> assign(:compras, compras)

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
            <h1 class="text-3xl font-bold text-white">Mis Compras</h1>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <!-- Total gastado -->
        <div class="bg-white shadow sm:rounded-lg mb-6 p-6">
          <div class="flex justify-between items-center">
            <div>
              <p class="text-sm text-gray-500">Total gastado</p>
              <p class="text-2xl font-bold text-gray-900">$<%= format_money(calcular_total(@compras)) %></p>
            </div>
            <div>
              <p class="text-sm text-gray-500">Total compras</p>
              <p class="text-2xl font-bold text-gray-900"><%= length(@compras) %></p>
            </div>
          </div>
        </div>

        <!-- Lista de compras -->
        <div class="bg-white shadow overflow-hidden sm:rounded-md">
          <%= if Enum.empty?(@compras) do %>
            <div class="text-center py-12">
              <p class="text-gray-500">No tienes compras realizadas.</p>
              <.link navigate={"/jugador/sorteos?cliente_id=#{@cliente.id}"} class="mt-4 inline-block text-purple-600 hover:underline">
                Ver sorteos disponibles
              </.link>
            </div>
          <% else %>
            <ul role="list" class="divide-y divide-gray-200">
              <%= for compra <- @compras do %>
                <li class="px-4 py-4 sm:px-6">
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-900">
                        Número: <span class="text-purple-600 font-bold"><%= compra.numero %></span>
                      </p>
                      <p class="text-sm text-gray-500">
                        <%= if compra.tipo == :billete_completo, do: "Billete completo", else: "Fracciones: #{Enum.join(compra.fracciones, ", ")}" %>
                      </p>
                      <p class="text-xs text-gray-400"><%= compra.created_at %></p>
                    </div>
                    <div class="text-right">
                      <p class="text-sm font-medium text-gray-900">$<%= format_money(compra.valor_pagado) %></p>
                      <span class={"px-2 py-1 text-xs rounded-full #{estado_color(compra.estado)}"}>
                        <%= humanize_estado(compra.estado) %>
                      </span>
                      
                      <%= if compra.estado == :activa do %>
                        <button phx-click="devolver" phx-value-id={compra.id}
                                data-confirm="¿Devolver esta compra?"
                                class="ml-2 text-red-600 hover:text-red-800 text-xs">
                          Devolver
                        </button>
                      <% end %>
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
  def handle_event("devolver", %{"id" => compra_id}, socket) do
    case ServidorCentral.devolver_compra(socket.assigns.cliente.id, compra_id) do
      {:ok, _} ->
        compras = ServidorCentral.historial_compras(socket.assigns.cliente.id)

        {:noreply,
         socket
         |> assign(:compras, compras)
         |> put_flash(:info, "Compra devuelta exitosamente")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error: #{inspect(reason)}")}
    end
  end

  defp calcular_total(compras) do
    Enum.reduce(compras, 0, fn c, acc ->
      if c.estado in [:activa, :ganadora, :perdedora], do: acc + c.valor_pagado, else: acc
    end)
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

  defp estado_color(:activa), do: "bg-blue-100 text-blue-800"
  defp estado_color(:devuelta), do: "bg-gray-100 text-gray-800"
  defp estado_color(:ganadora), do: "bg-green-100 text-green-800"
  defp estado_color(:perdedora), do: "bg-red-100 text-red-800"
  defp estado_color(_), do: "bg-gray-100 text-gray-800"

  defp humanize_estado(:activa), do: "Activa"
  defp humanize_estado(:devuelta), do: "Devuelta"
  defp humanize_estado(:ganadora), do: "Ganadora"
  defp humanize_estado(:perdedora), do: "Perdedora"
  defp humanize_estado(estado), do: to_string(estado)
end
