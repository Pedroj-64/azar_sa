defmodule AzarSa.Application do
  @moduledoc """
  Aplicación OTP principal para el sistema Azar S.A.

  Este módulo configura el árbol de supervisión con todos los componentes:
  - Servidor Central (ServidorCentral)
  - Supervisor de Sorteos (SorteoSupervisor)
  - Sistema de Bitácora (Bitacora)
  - Sistema de Notificaciones (Notificaciones)
  - Sistema de Fecha/Hora simulada (SistemaFecha)
  """

  use Application

  @impl true
  def start(_type, _args) do
    # Inicializar datos de prueba si no existen
    AzarSa.Data.Store.inicializar_datos_prueba()

    children = [
      # Telemetría para métricas
      AzarSaWeb.Telemetry,

      # Cluster DNS para sistema distribuido
      {DNSCluster, query: Application.get_env(:azar_sa, :dns_cluster_query) || :ignore},

      # PubSub para comunicación entre procesos y notificaciones
      {Phoenix.PubSub, name: AzarSa.PubSub},

      # Registry para registrar servidores de sorteos por ID
      {Registry, keys: :unique, name: AzarSa.SorteoRegistry},

      # Sistema de Bitácora - Registra todas las operaciones
      AzarSa.Bitacora.Logger,

      # Sistema de Fecha simulada
      AzarSa.Sistema.Fecha,

      # Sistema de Notificaciones
      AzarSa.Notificaciones.Servidor,

      # Supervisor de Sorteos - Maneja GenServers por sorteo
      AzarSa.Servidores.SorteoSupervisor,

      # Servidor Central - Punto de entrada para todas las solicitudes
      AzarSa.Servidores.ServidorCentral,

      # Endpoint Phoenix - Interfaz web
      AzarSaWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: AzarSa.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    AzarSaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
