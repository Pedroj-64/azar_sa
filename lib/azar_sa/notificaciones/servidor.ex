defmodule AzarSa.Notificaciones.Servidor do
  @moduledoc """
  Sistema de Notificaciones para jugadores.

  Envía notificaciones a los jugadores sobre:
  - Resultados de sorteos
  - Premios ganados
  - Mensajes del sistema

  Utiliza Phoenix.PubSub para comunicación en tiempo real.
  """

  use GenServer
  require Logger

  alias Phoenix.PubSub

  @name __MODULE__
  @pubsub AzarSa.PubSub

  # ============================================================================
  # API Pública
  # ============================================================================

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @doc """
  Envía una notificación a un cliente específico.
  """
  def enviar(cliente_id, mensaje) do
    GenServer.cast(@name, {:enviar, cliente_id, mensaje})
  end

  @doc """
  Envía una notificación a todos los clientes.
  """
  def broadcast(mensaje) do
    GenServer.cast(@name, {:broadcast, mensaje})
  end

  @doc """
  Suscribe un proceso a las notificaciones de un cliente.
  """
  def suscribir(cliente_id) do
    PubSub.subscribe(@pubsub, "notificaciones:#{cliente_id}")
  end

  @doc """
  Suscribe un proceso a las notificaciones globales.
  """
  def suscribir_global do
    PubSub.subscribe(@pubsub, "notificaciones:global")
  end

  # ============================================================================
  # Callbacks del GenServer
  # ============================================================================

  @impl true
  def init(_state) do
    Logger.info("Sistema de Notificaciones iniciado")
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:enviar, cliente_id, mensaje}, state) do
    notificacion = crear_notificacion(mensaje)

    # Publicar via PubSub para LiveView
    PubSub.broadcast(@pubsub, "notificaciones:#{cliente_id}", {:notificacion, notificacion})

    # Persistir en el cliente
    AzarSa.Clientes.agregar_notificacion(cliente_id, mensaje)

    Logger.info("Notificación enviada a cliente #{cliente_id}")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:broadcast, mensaje}, state) do
    notificacion = crear_notificacion(mensaje)

    PubSub.broadcast(@pubsub, "notificaciones:global", {:notificacion, notificacion})

    Logger.info("Notificación global enviada")
    {:noreply, state}
  end

  # ============================================================================
  # Funciones Privadas
  # ============================================================================

  defp crear_notificacion(mensaje) do
    %{
      id: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower),
      mensaje: mensaje,
      fecha: DateTime.utc_now() |> DateTime.to_iso8601(),
      leida: false
    }
  end
end
