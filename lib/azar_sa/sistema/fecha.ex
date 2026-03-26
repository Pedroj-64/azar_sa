defmodule AzarSa.Sistema.Fecha do
  @moduledoc """
  Sistema de Fecha simulada.

  Permite al administrador avanzar la fecha del sistema para
  ejecutar sorteos sin esperar a la fecha real.

  Cuando se actualiza la fecha:
  1. Se ejecutan todos los sorteos pendientes hasta esa fecha
  2. Se asignan números ganadores aleatorios
  3. Se envían notificaciones a los ganadores
  """

  use GenServer
  require Logger

  @name __MODULE__

  # ============================================================================
  # API Pública
  # ============================================================================

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @doc """
  Obtiene la fecha actual del sistema.
  """
  def fecha_actual do
    GenServer.call(@name, :fecha_actual)
  end

  @doc """
  Actualiza la fecha del sistema.
  """
  def actualizar_fecha(nueva_fecha) when is_binary(nueva_fecha) do
    case Date.from_iso8601(nueva_fecha) do
      {:ok, fecha} -> actualizar_fecha(fecha)
      error -> error
    end
  end

  def actualizar_fecha(%Date{} = nueva_fecha) do
    GenServer.call(@name, {:actualizar_fecha, nueva_fecha})
  end

  @doc """
  Resetea la fecha al día actual real.
  """
  def resetear do
    GenServer.call(@name, :resetear)
  end

  # ============================================================================
  # Callbacks del GenServer
  # ============================================================================

  @impl true
  def init(_state) do
    fecha = Date.utc_today()
    Logger.info("Sistema de Fecha iniciado: #{fecha}")
    {:ok, %{fecha: fecha, fecha_real: fecha}}
  end

  @impl true
  def handle_call(:fecha_actual, _from, state) do
    {:reply, state.fecha, state}
  end

  @impl true
  def handle_call({:actualizar_fecha, nueva_fecha}, _from, state) do
    if Date.compare(nueva_fecha, state.fecha) in [:gt, :eq] do
      Logger.info("Fecha del sistema actualizada: #{state.fecha} -> #{nueva_fecha}")
      {:reply, {:ok, nueva_fecha}, %{state | fecha: nueva_fecha}}
    else
      {:reply, {:error, :fecha_anterior_no_permitida}, state}
    end
  end

  @impl true
  def handle_call(:resetear, _from, state) do
    fecha_hoy = Date.utc_today()
    {:reply, {:ok, fecha_hoy}, %{state | fecha: fecha_hoy}}
  end
end
