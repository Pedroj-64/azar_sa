defmodule AzarSa.Servidores.ServidorCentral do
  @moduledoc """
  Servidor Central del Sistema Azar S.A.

  Este GenServer actúa como punto de entrada para todas las solicitudes
  de los clientes (administradores y jugadores). Su función principal es:

  1. Recibir solicitudes de la red
  2. Redirigir a los servidores especializados por sorteo
  3. Registrar todas las operaciones en la bitácora
  4. Coordinar la comunicación entre componentes

  ## Arquitectura

  ```
  [Cliente Admin] ──┐
                    ├──> [Servidor Central] ──> [ServidorSorteo 1]
  [Cliente Jugador]─┘                       ──> [ServidorSorteo 2]
                                            ──> [ServidorSorteo N]
  ```
  """

  use GenServer
  require Logger

  alias AzarSa.Bitacora.Logger, as: Bitacora
  alias AzarSa.Servidores.SorteoSupervisor
  alias AzarSa.Servidores.ServidorSorteo

  @name __MODULE__

  # ============================================================================
  # API Pública
  # ============================================================================

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @doc """
  Procesa una solicitud genérica.
  """
  def procesar_solicitud(tipo, params) do
    GenServer.call(@name, {:procesar, tipo, params})
  end

  # --- Operaciones de Sorteos ---

  def crear_sorteo(params) do
    GenServer.call(@name, {:crear_sorteo, params})
  end

  def listar_sorteos do
    GenServer.call(@name, :listar_sorteos)
  end

  def obtener_sorteo(sorteo_id) do
    GenServer.call(@name, {:obtener_sorteo, sorteo_id})
  end

  def eliminar_sorteo(sorteo_id) do
    GenServer.call(@name, {:eliminar_sorteo, sorteo_id})
  end

  def ejecutar_sorteo(sorteo_id) do
    GenServer.call(@name, {:ejecutar_sorteo, sorteo_id})
  end

  def actualizar_fecha_sistema(nueva_fecha) do
    GenServer.call(@name, {:actualizar_fecha, nueva_fecha})
  end

  # --- Operaciones de Premios ---

  def crear_premio(sorteo_id, params) do
    GenServer.call(@name, {:crear_premio, sorteo_id, params})
  end

  def listar_premios do
    GenServer.call(@name, :listar_premios)
  end

  def eliminar_premio(sorteo_id, premio_id) do
    GenServer.call(@name, {:eliminar_premio, sorteo_id, premio_id})
  end

  # --- Operaciones de Clientes ---

  def registrar_cliente(params) do
    GenServer.call(@name, {:registrar_cliente, params})
  end

  def autenticar_cliente(documento, password) do
    GenServer.call(@name, {:autenticar_cliente, documento, password})
  end

  def obtener_cliente(cliente_id) do
    GenServer.call(@name, {:obtener_cliente, cliente_id})
  end

  # --- Operaciones de Compras ---

  def comprar_billete(cliente_id, sorteo_id, numero) do
    GenServer.call(@name, {:comprar_billete, cliente_id, sorteo_id, numero})
  end

  def comprar_fracciones(cliente_id, sorteo_id, numero, fracciones) do
    GenServer.call(@name, {:comprar_fracciones, cliente_id, sorteo_id, numero, fracciones})
  end

  def devolver_compra(cliente_id, compra_id) do
    GenServer.call(@name, {:devolver_compra, cliente_id, compra_id})
  end

  def historial_compras(cliente_id) do
    GenServer.call(@name, {:historial_compras, cliente_id})
  end

  def numeros_disponibles(sorteo_id) do
    GenServer.call(@name, {:numeros_disponibles, sorteo_id})
  end

  # --- Consultas ---

  def clientes_sorteo(sorteo_id) do
    GenServer.call(@name, {:clientes_sorteo, sorteo_id})
  end

  def ingresos_sorteo(sorteo_id) do
    GenServer.call(@name, {:ingresos_sorteo, sorteo_id})
  end

  def balance_sorteos_pasados do
    GenServer.call(@name, :balance_sorteos_pasados)
  end

  def premios_cliente(cliente_id) do
    GenServer.call(@name, {:premios_cliente, cliente_id})
  end

  def balance_cliente(cliente_id) do
    GenServer.call(@name, {:balance_cliente, cliente_id})
  end

  def notificaciones_cliente(cliente_id) do
    GenServer.call(@name, {:notificaciones_cliente, cliente_id})
  end

  # ============================================================================
  # Callbacks del GenServer
  # ============================================================================

  @impl true
  def init(_state) do
    Logger.info("Servidor Central iniciado")
    Bitacora.registrar("SISTEMA", "Servidor Central iniciado", :ok)
    {:ok, %{iniciado_en: DateTime.utc_now()}}
  end

  @impl true
  def handle_call({:crear_sorteo, params}, _from, state) do
    resultado = SorteoSupervisor.crear_sorteo(params)
    registrar_operacion("CREAR_SORTEO", params, resultado)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call(:listar_sorteos, _from, state) do
    resultado = SorteoSupervisor.listar_sorteos()
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:obtener_sorteo, sorteo_id}, _from, state) do
    resultado = SorteoSupervisor.obtener_sorteo(sorteo_id)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:eliminar_sorteo, sorteo_id}, _from, state) do
    resultado = SorteoSupervisor.eliminar_sorteo(sorteo_id)
    registrar_operacion("ELIMINAR_SORTEO", %{sorteo_id: sorteo_id}, resultado)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:ejecutar_sorteo, sorteo_id}, _from, state) do
    resultado = redirigir_a_servidor_sorteo(sorteo_id, :ejecutar)
    registrar_operacion("EJECUTAR_SORTEO", %{sorteo_id: sorteo_id}, resultado)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:actualizar_fecha, nueva_fecha}, _from, state) do
    resultado = AzarSa.Sistema.Fecha.actualizar_fecha(nueva_fecha)

    # Ejecutar sorteos pendientes hasta la nueva fecha
    case resultado do
      {:ok, fecha} ->
        ejecutar_sorteos_pendientes(fecha)

      _ ->
        :ok
    end

    registrar_operacion("ACTUALIZAR_FECHA", %{fecha: nueva_fecha}, resultado)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:crear_premio, sorteo_id, params}, _from, state) do
    resultado = redirigir_a_servidor_sorteo(sorteo_id, {:crear_premio, params})
    registrar_operacion("CREAR_PREMIO", Map.merge(params, %{sorteo_id: sorteo_id}), resultado)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call(:listar_premios, _from, state) do
    resultado = SorteoSupervisor.listar_todos_los_premios()
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:eliminar_premio, sorteo_id, premio_id}, _from, state) do
    resultado = redirigir_a_servidor_sorteo(sorteo_id, {:eliminar_premio, premio_id})

    registrar_operacion(
      "ELIMINAR_PREMIO",
      %{sorteo_id: sorteo_id, premio_id: premio_id},
      resultado
    )

    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:registrar_cliente, params}, _from, state) do
    resultado = AzarSa.Clientes.registrar(params)
    registrar_operacion("REGISTRAR_CLIENTE", %{documento: params[:documento]}, resultado)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:autenticar_cliente, documento, password}, _from, state) do
    resultado = AzarSa.Clientes.autenticar(documento, password)
    registrar_operacion("AUTENTICAR_CLIENTE", %{documento: documento}, resultado)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:obtener_cliente, cliente_id}, _from, state) do
    resultado = AzarSa.Clientes.obtener(cliente_id)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:comprar_billete, cliente_id, sorteo_id, numero}, _from, state) do
    resultado = redirigir_a_servidor_sorteo(sorteo_id, {:comprar_billete, cliente_id, numero})

    registrar_operacion(
      "COMPRAR_BILLETE",
      %{cliente_id: cliente_id, sorteo_id: sorteo_id, numero: numero},
      resultado
    )

    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:comprar_fracciones, cliente_id, sorteo_id, numero, fracciones}, _from, state) do
    resultado =
      redirigir_a_servidor_sorteo(
        sorteo_id,
        {:comprar_fracciones, cliente_id, numero, fracciones}
      )

    registrar_operacion(
      "COMPRAR_FRACCIONES",
      %{cliente_id: cliente_id, sorteo_id: sorteo_id, numero: numero},
      resultado
    )

    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:devolver_compra, cliente_id, compra_id}, _from, state) do
    resultado = devolver_compra_impl(cliente_id, compra_id)

    registrar_operacion(
      "DEVOLVER_COMPRA",
      %{cliente_id: cliente_id, compra_id: compra_id},
      resultado
    )

    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:historial_compras, cliente_id}, _from, state) do
    resultado = SorteoSupervisor.historial_compras_cliente(cliente_id)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:numeros_disponibles, sorteo_id}, _from, state) do
    resultado = redirigir_a_servidor_sorteo(sorteo_id, :numeros_disponibles)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:clientes_sorteo, sorteo_id}, _from, state) do
    resultado = redirigir_a_servidor_sorteo(sorteo_id, :clientes_sorteo)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:ingresos_sorteo, sorteo_id}, _from, state) do
    resultado = redirigir_a_servidor_sorteo(sorteo_id, :ingresos)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call(:balance_sorteos_pasados, _from, state) do
    resultado = SorteoSupervisor.balance_general()
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:premios_cliente, cliente_id}, _from, state) do
    resultado = SorteoSupervisor.premios_cliente(cliente_id)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:balance_cliente, cliente_id}, _from, state) do
    resultado = calcular_balance_cliente(cliente_id)
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:notificaciones_cliente, cliente_id}, _from, state) do
    resultado = AzarSa.Clientes.obtener_notificaciones(cliente_id)
    {:reply, resultado, state}
  end

  # ============================================================================
  # Funciones Privadas
  # ============================================================================

  defp redirigir_a_servidor_sorteo(sorteo_id, mensaje) do
    case SorteoSupervisor.obtener_servidor(sorteo_id) do
      {:ok, pid} -> ServidorSorteo.call(pid, mensaje)
      error -> error
    end
  end

  defp ejecutar_sorteos_pendientes(fecha_actual) do
    SorteoSupervisor.ejecutar_sorteos_hasta_fecha(fecha_actual)
  end

  defp devolver_compra_impl(cliente_id, compra_id) do
    SorteoSupervisor.devolver_compra(cliente_id, compra_id)
  end

  defp calcular_balance_cliente(cliente_id) do
    compras = SorteoSupervisor.historial_compras_cliente(cliente_id)
    premios = SorteoSupervisor.premios_cliente(cliente_id)

    total_gastado = Enum.reduce(compras, 0, fn c, acc -> acc + (c.valor_pagado || 0) end)
    total_ganado = Enum.reduce(premios, 0, fn p, acc -> acc + (p[:valor] || 0) end)

    {:ok,
     %{
       total_gastado: total_gastado,
       total_ganado: total_ganado,
       balance: total_ganado - total_gastado
     }}
  end

  defp registrar_operacion(tipo, params, resultado) do
    estado =
      case resultado do
        {:ok, _} -> :ok
        :ok -> :ok
        _ -> :negado
      end

    params_str = inspect(params, limit: 50)
    Bitacora.registrar(tipo, params_str, estado)
  end
end
