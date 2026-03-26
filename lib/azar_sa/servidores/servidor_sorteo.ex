defmodule AzarSa.Servidores.ServidorSorteo do
  @moduledoc """
  Servidor especializado para un sorteo individual.

  Cada instancia de este GenServer maneja toda la información
  y operaciones de un sorteo específico:

  - Datos del sorteo (nombre, fecha, valor, fracciones, billetes)
  - Premios asociados al sorteo
  - Compras de billetes y fracciones
  - Disponibilidad de números
  - Ejecución del sorteo y asignación de ganadores

  Los datos se persisten en archivos JSON en `priv/data/sorteos/`.
  """

  use GenServer
  require Logger

  alias AzarSa.Sorteos.Sorteo
  alias AzarSa.Premios.Premio
  alias AzarSa.Apuestas.Compra
  alias AzarSa.Data.Store
  alias AzarSa.Notificaciones.Servidor, as: Notificaciones

  # ============================================================================
  # API Pública
  # ============================================================================

  def start_link(%Sorteo{} = sorteo) do
    GenServer.start_link(__MODULE__, sorteo, name: via_tuple(sorteo.id))
  end

  def call(pid, mensaje) do
    GenServer.call(pid, mensaje)
  end

  def obtener_sorteo(pid) do
    GenServer.call(pid, :obtener_sorteo)
  end

  def obtener_premios(pid) do
    GenServer.call(pid, :obtener_premios)
  end

  def puede_eliminarse?(pid) do
    GenServer.call(pid, :puede_eliminarse?)
  end

  def ejecutar(pid) do
    GenServer.call(pid, :ejecutar)
  end

  def compras_cliente(pid, cliente_id) do
    GenServer.call(pid, {:compras_cliente, cliente_id})
  end

  def premios_ganados_cliente(pid, cliente_id) do
    GenServer.call(pid, {:premios_ganados_cliente, cliente_id})
  end

  def devolver_compra(pid, cliente_id, compra_id) do
    GenServer.call(pid, {:devolver_compra, cliente_id, compra_id})
  end

  def balance(pid) do
    GenServer.call(pid, :balance)
  end

  # ============================================================================
  # Callbacks del GenServer
  # ============================================================================

  @impl true
  def init(%Sorteo{} = sorteo) do
    # Cargar datos persistidos si existen
    state = cargar_estado(sorteo)

    Logger.info("Servidor de sorteo iniciado: #{sorteo.nombre}")
    {:ok, state}
  end

  @impl true
  def handle_call(:obtener_sorteo, _from, state) do
    {:reply, {:ok, state.sorteo}, state}
  end

  @impl true
  def handle_call(:obtener_premios, _from, state) do
    {:reply, {:ok, state.premios}, state}
  end

  @impl true
  def handle_call(:puede_eliminarse?, _from, state) do
    puede = Enum.empty?(state.premios)
    {:reply, puede, state}
  end

  @impl true
  def handle_call({:crear_premio, params}, _from, state) do
    if state.sorteo.estado != :pendiente do
      {:reply, {:error, :sorteo_ya_realizado}, state}
    else
      premio = Premio.new(Map.put(params, :sorteo_id, state.sorteo.id))

      nuevo_estado = %{
        state
        | premios: [premio | state.premios],
          sorteo: %{state.sorteo | premios: [premio.id | state.sorteo.premios]}
      }

      persistir_estado(nuevo_estado)
      {:reply, {:ok, premio}, nuevo_estado}
    end
  end

  @impl true
  def handle_call({:eliminar_premio, premio_id}, _from, state) do
    if tiene_clientes?(state) do
      {:reply, {:error, :sorteo_tiene_clientes}, state}
    else
      nuevos_premios = Enum.reject(state.premios, &(&1.id == premio_id))

      nuevo_sorteo = %{
        state.sorteo
        | premios: Enum.reject(state.sorteo.premios, &(&1 == premio_id))
      }

      nuevo_estado = %{state | premios: nuevos_premios, sorteo: nuevo_sorteo}
      persistir_estado(nuevo_estado)
      {:reply, {:ok, :eliminado}, nuevo_estado}
    end
  end

  @impl true
  def handle_call(:ejecutar, _from, state) do
    if state.sorteo.estado != :pendiente do
      {:reply, {:error, :sorteo_ya_realizado}, state}
    else
      nuevo_estado = ejecutar_sorteo(state)
      persistir_estado(nuevo_estado)
      enviar_notificaciones_ganadores(nuevo_estado)
      {:reply, {:ok, nuevo_estado.sorteo}, nuevo_estado}
    end
  end

  @impl true
  def handle_call({:comprar_billete, cliente_id, numero}, _from, state) do
    cond do
      state.sorteo.estado != :pendiente ->
        {:reply, {:error, :sorteo_no_disponible}, state}

      numero < 1 or numero > state.sorteo.cantidad_billetes ->
        {:reply, {:error, :numero_invalido}, state}

      billete_vendido?(state, numero) ->
        {:reply, {:error, :billete_no_disponible}, state}

      true ->
        compra =
          Compra.new_billete_completo(%{
            cliente_id: cliente_id,
            sorteo_id: state.sorteo.id,
            numero: numero,
            cantidad_fracciones: state.sorteo.cantidad_fracciones,
            valor_billete: state.sorteo.valor_billete
          })

        nuevo_estado = %{state | compras: [compra | state.compras]}
        persistir_estado(nuevo_estado)
        {:reply, {:ok, compra}, nuevo_estado}
    end
  end

  @impl true
  def handle_call({:comprar_fracciones, cliente_id, numero, fracciones}, _from, state) do
    cond do
      state.sorteo.estado != :pendiente ->
        {:reply, {:error, :sorteo_no_disponible}, state}

      numero < 1 or numero > state.sorteo.cantidad_billetes ->
        {:reply, {:error, :numero_invalido}, state}

      not fracciones_disponibles?(state, numero, fracciones) ->
        {:reply, {:error, :fracciones_no_disponibles}, state}

      true ->
        compra =
          Compra.new_fracciones(%{
            cliente_id: cliente_id,
            sorteo_id: state.sorteo.id,
            numero: numero,
            fracciones: fracciones,
            cantidad_fracciones_total: state.sorteo.cantidad_fracciones,
            valor_billete: state.sorteo.valor_billete
          })

        nuevo_estado = %{state | compras: [compra | state.compras]}
        persistir_estado(nuevo_estado)
        {:reply, {:ok, compra}, nuevo_estado}
    end
  end

  @impl true
  def handle_call({:devolver_compra, cliente_id, compra_id}, _from, state) do
    if state.sorteo.estado != :pendiente do
      {:reply, {:error, :sorteo_ya_realizado}, state}
    else
      case Enum.find(state.compras, &(&1.id == compra_id and &1.cliente_id == cliente_id)) do
        nil ->
          {:reply, {:error, :compra_no_encontrada}, state}

        compra ->
          compra_actualizada = %{compra | estado: :devuelta}

          nuevas_compras =
            Enum.map(state.compras, fn c ->
              if c.id == compra_id, do: compra_actualizada, else: c
            end)

          nuevo_estado = %{state | compras: nuevas_compras}
          persistir_estado(nuevo_estado)
          {:reply, {:ok, compra_actualizada}, nuevo_estado}
      end
    end
  end

  @impl true
  def handle_call(:numeros_disponibles, _from, state) do
    disponibles = calcular_disponibilidad(state)
    {:reply, {:ok, disponibles}, state}
  end

  @impl true
  def handle_call(:clientes_sorteo, _from, state) do
    clientes = obtener_clientes_sorteo(state)
    {:reply, {:ok, clientes}, state}
  end

  @impl true
  def handle_call(:ingresos, _from, state) do
    ingresos = calcular_ingresos(state)
    {:reply, {:ok, ingresos}, state}
  end

  @impl true
  def handle_call({:compras_cliente, cliente_id}, _from, state) do
    compras = Enum.filter(state.compras, &(&1.cliente_id == cliente_id))
    {:reply, {:ok, compras}, state}
  end

  @impl true
  def handle_call({:premios_ganados_cliente, cliente_id}, _from, state) do
    premios = obtener_premios_cliente(state, cliente_id)
    {:reply, {:ok, premios}, state}
  end

  @impl true
  def handle_call(:balance, _from, state) do
    balance = calcular_balance(state)
    {:reply, {:ok, balance}, state}
  end

  # ============================================================================
  # Funciones Privadas
  # ============================================================================

  defp via_tuple(sorteo_id) do
    {:via, Registry, {AzarSa.SorteoRegistry, sorteo_id}}
  end

  defp cargar_estado(sorteo) do
    case Store.cargar_sorteo_completo(sorteo.id) do
      {:ok, data} ->
        %{
          sorteo: Sorteo.from_map(data["sorteo"]),
          premios: Enum.map(data["premios"] || [], &Premio.from_map/1),
          compras: Enum.map(data["compras"] || [], &Compra.from_map/1)
        }

      {:error, _} ->
        %{
          sorteo: sorteo,
          premios: [],
          compras: []
        }
    end
  end

  defp persistir_estado(state) do
    data = %{
      "sorteo" => Sorteo.to_map(state.sorteo),
      "premios" => Enum.map(state.premios, &Premio.to_map/1),
      "compras" => Enum.map(state.compras, &Compra.to_map/1)
    }

    Store.guardar_sorteo_completo(state.sorteo.id, data)
  end

  defp ejecutar_sorteo(state) do
    # Generar números ganadores aleatorios para cada premio
    numeros_disponibles = 1..state.sorteo.cantidad_billetes |> Enum.to_list()

    {premios_actualizados, _} =
      Enum.map_reduce(state.premios, numeros_disponibles, fn premio, nums ->
        numero_ganador = Enum.random(nums)
        nums_restantes = List.delete(nums, numero_ganador)

        # Encontrar ganadores (clientes que compraron este número)
        ganadores =
          Enum.filter(state.compras, fn c ->
            c.numero == numero_ganador and c.estado == :activa
          end)
          |> Enum.map(fn c ->
            %{
              cliente_id: c.cliente_id,
              tipo: c.tipo,
              fracciones: c.fracciones
            }
          end)

        premio_actualizado = %{premio | numero_ganador: numero_ganador, ganadores: ganadores}

        {premio_actualizado, nums_restantes}
      end)

    # Actualizar estado de compras
    numeros_ganadores = Enum.map(premios_actualizados, & &1.numero_ganador)

    compras_actualizadas =
      Enum.map(state.compras, fn compra ->
        if compra.estado == :activa do
          if compra.numero in numeros_ganadores do
            premio = Enum.find(premios_actualizados, &(&1.numero_ganador == compra.numero))

            valor_ganado =
              calcular_premio_compra(compra, premio, state.sorteo.cantidad_fracciones)

            %{compra | estado: :ganadora, premio_obtenido: valor_ganado}
          else
            %{compra | estado: :perdedora}
          end
        else
          compra
        end
      end)

    # Crear estructura de números ganadores
    numeros_ganadores_info =
      Enum.map(premios_actualizados, fn p ->
        %{
          premio_id: p.id,
          premio_nombre: p.nombre,
          numero: p.numero_ganador,
          valor: p.valor
        }
      end)

    nuevo_sorteo = %{
      state.sorteo
      | estado: :realizado,
        numeros_ganadores: numeros_ganadores_info,
        updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    %{state | sorteo: nuevo_sorteo, premios: premios_actualizados, compras: compras_actualizadas}
  end

  defp calcular_premio_compra(compra, premio, cantidad_fracciones_total) do
    case compra.tipo do
      :billete_completo ->
        premio.valor

      :fraccion ->
        premio.valor / cantidad_fracciones_total * length(compra.fracciones)
    end
  end

  defp enviar_notificaciones_ganadores(state) do
    Enum.each(state.premios, fn premio ->
      Enum.each(premio.ganadores, fn ganador ->
        mensaje = """
        ¡Felicidades! Has ganado en el sorteo "#{state.sorteo.nombre}".
        Premio: #{premio.nombre}
        Número ganador: #{premio.numero_ganador}
        Valor del premio: $#{premio.valor}
        """

        Notificaciones.enviar(ganador.cliente_id, mensaje)
      end)
    end)
  end

  defp billete_vendido?(state, numero) do
    Enum.any?(state.compras, fn c ->
      c.numero == numero and
        c.tipo == :billete_completo and
        c.estado == :activa
    end)
  end

  defp fracciones_disponibles?(state, numero, fracciones_solicitadas) do
    fracciones_vendidas =
      state.compras
      |> Enum.filter(fn c -> c.numero == numero and c.estado == :activa end)
      |> Enum.flat_map(& &1.fracciones)
      |> MapSet.new()

    solicitadas_set = MapSet.new(fracciones_solicitadas)

    MapSet.disjoint?(fracciones_vendidas, solicitadas_set) and
      Enum.all?(fracciones_solicitadas, fn f ->
        f >= 1 and f <= state.sorteo.cantidad_fracciones
      end)
  end

  defp calcular_disponibilidad(state) do
    todos_numeros = 1..state.sorteo.cantidad_billetes |> Enum.to_list()

    Enum.map(todos_numeros, fn numero ->
      compras_numero =
        Enum.filter(state.compras, fn c ->
          c.numero == numero and c.estado == :activa
        end)

      cond do
        # Billete completo vendido
        Enum.any?(compras_numero, &(&1.tipo == :billete_completo)) ->
          %{numero: numero, disponible: false, fracciones_disponibles: []}

        # Algunas fracciones vendidas
        length(compras_numero) > 0 ->
          fracciones_vendidas = Enum.flat_map(compras_numero, & &1.fracciones) |> MapSet.new()
          todas_fracciones = 1..state.sorteo.cantidad_fracciones |> MapSet.new()

          disponibles =
            MapSet.difference(todas_fracciones, fracciones_vendidas) |> MapSet.to_list()

          %{
            numero: numero,
            disponible: true,
            fracciones_disponibles: disponibles,
            billete_completo: false
          }

        # Todo disponible
        true ->
          %{
            numero: numero,
            disponible: true,
            fracciones_disponibles: Enum.to_list(1..state.sorteo.cantidad_fracciones),
            billete_completo: true
          }
      end
    end)
  end

  defp tiene_clientes?(state) do
    Enum.any?(state.compras, &(&1.estado == :activa))
  end

  defp obtener_clientes_sorteo(state) do
    compras_activas = Enum.filter(state.compras, &(&1.estado == :activa))

    clientes_ids = Enum.map(compras_activas, & &1.cliente_id) |> Enum.uniq()

    clientes =
      Enum.map(clientes_ids, fn id ->
        case AzarSa.Clientes.obtener(id) do
          {:ok, cliente} -> cliente
          _ -> nil
        end
      end)
      |> Enum.filter(&(&1 != nil))
      |> Enum.sort_by(& &1.nombre)

    billetes_completos =
      Enum.filter(compras_activas, &(&1.tipo == :billete_completo))
      |> Enum.map(& &1.cliente_id)
      |> Enum.uniq()

    fracciones =
      Enum.filter(compras_activas, &(&1.tipo == :fraccion))
      |> Enum.map(& &1.cliente_id)
      |> Enum.uniq()

    %{
      total: length(clientes),
      clientes: clientes,
      compradores_billete_completo: Enum.filter(clientes, &(&1.id in billetes_completos)),
      compradores_fracciones: Enum.filter(clientes, &(&1.id in fracciones))
    }
  end

  defp calcular_ingresos(state) do
    compras_activas = Enum.filter(state.compras, &(&1.estado in [:activa, :ganadora, :perdedora]))
    total = Enum.reduce(compras_activas, 0, fn c, acc -> acc + c.valor_pagado end)

    %{
      total: total,
      cantidad_compras: length(compras_activas)
    }
  end

  defp obtener_premios_cliente(state, cliente_id) do
    if state.sorteo.estado != :realizado do
      []
    else
      Enum.flat_map(state.premios, fn premio ->
        ganadores_cliente = Enum.filter(premio.ganadores, &(&1.cliente_id == cliente_id))

        Enum.map(ganadores_cliente, fn g ->
          valor =
            case g.tipo do
              :billete_completo -> premio.valor
              :fraccion -> premio.valor / state.sorteo.cantidad_fracciones * length(g.fracciones)
            end

          %{
            sorteo_nombre: state.sorteo.nombre,
            premio_nombre: premio.nombre,
            numero: premio.numero_ganador,
            valor: valor
          }
        end)
      end)
    end
  end

  defp calcular_balance(state) do
    ingresos = calcular_ingresos(state)

    premios_entregados =
      if state.sorteo.estado == :realizado do
        Enum.reduce(state.premios, 0, fn premio, acc ->
          if length(premio.ganadores) > 0, do: acc + premio.valor, else: acc
        end)
      else
        0
      end

    %{
      ingresos: ingresos.total,
      premios_entregados: premios_entregados,
      ganancia: ingresos.total - premios_entregados
    }
  end
end
