defmodule AzarSa.Servidores.SorteoSupervisor do
  @moduledoc """
  Supervisor dinámico para los servidores de sorteos.

  Este módulo gestiona la creación, supervisión y eliminación de
  servidores individuales para cada sorteo. Cada sorteo tiene su
  propio GenServer que maneja:
  - Información del sorteo
  - Premios asociados
  - Compras realizadas
  - Ejecución del sorteo

  ## Arquitectura

  ```
  [SorteoSupervisor]
       │
       ├── [ServidorSorteo: "Lotería de Medellín"]
       ├── [ServidorSorteo: "Lotería de Bogotá"]
       └── [ServidorSorteo: "Lotería del Valle"]
  ```
  """

  use DynamicSupervisor
  require Logger

  alias AzarSa.Servidores.ServidorSorteo
  alias AzarSa.Sorteos.Sorteo
  alias AzarSa.Data.Store

  @name __MODULE__

  # ============================================================================
  # API Pública
  # ============================================================================

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: @name)
  end

  @impl true
  def init(:ok) do
    # Iniciar supervisor y cargar sorteos existentes después
    result = DynamicSupervisor.init(strategy: :one_for_one)

    # Cargar sorteos existentes en un proceso separado
    Task.start(fn ->
      # Pequeña espera para que el supervisor esté completamente listo
      Process.sleep(100)
      cargar_sorteos_desde_archivo()
    end)

    result
  end

  @doc """
  Crea un nuevo sorteo e inicia su servidor asociado.
  """
  def crear_sorteo(params) do
    sorteo = Sorteo.new(params)

    case iniciar_servidor_sorteo(sorteo) do
      {:ok, _pid} ->
        Logger.info("Sorteo creado: #{sorteo.nombre} (#{sorteo.id})")
        {:ok, sorteo}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Lista todos los sorteos ordenados por fecha.
  """
  def listar_sorteos do
    obtener_todos_los_servidores()
    |> Enum.map(fn {_id, pid} -> ServidorSorteo.obtener_sorteo(pid) end)
    |> Enum.filter(fn
      {:ok, _} -> true
      _ -> false
    end)
    |> Enum.map(fn {:ok, sorteo} -> sorteo end)
    |> Enum.sort_by(fn s -> s.fecha end, Date)
  end

  @doc """
  Obtiene un sorteo por su ID.
  """
  def obtener_sorteo(sorteo_id) do
    case obtener_servidor(sorteo_id) do
      {:ok, pid} -> ServidorSorteo.obtener_sorteo(pid)
      error -> error
    end
  end

  @doc """
  Obtiene el PID del servidor de un sorteo.
  """
  def obtener_servidor(sorteo_id) do
    case Registry.lookup(AzarSa.SorteoRegistry, sorteo_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :sorteo_no_encontrado}
    end
  end

  @doc """
  Elimina un sorteo (solo si no tiene premios).
  """
  def eliminar_sorteo(sorteo_id) do
    case obtener_servidor(sorteo_id) do
      {:ok, pid} ->
        case ServidorSorteo.puede_eliminarse?(pid) do
          true ->
            DynamicSupervisor.terminate_child(@name, pid)
            Store.eliminar_sorteo(sorteo_id)
            {:ok, :eliminado}

          false ->
            {:error, :tiene_premios_asociados}
        end

      error ->
        error
    end
  end

  @doc """
  Ejecuta todos los sorteos pendientes hasta una fecha dada.
  """
  def ejecutar_sorteos_hasta_fecha(fecha) do
    listar_sorteos()
    |> Enum.filter(fn s ->
      s.estado == :pendiente and
        Date.compare(s.fecha, fecha) in [:lt, :eq]
    end)
    |> Enum.each(fn sorteo ->
      case obtener_servidor(sorteo.id) do
        {:ok, pid} -> ServidorSorteo.ejecutar(pid)
        _ -> :ok
      end
    end)
  end

  @doc """
  Lista todos los premios de todos los sorteos.
  """
  def listar_todos_los_premios do
    obtener_todos_los_servidores()
    |> Enum.flat_map(fn {_id, pid} ->
      case ServidorSorteo.obtener_premios(pid) do
        {:ok, premios} -> premios
        _ -> []
      end
    end)
  end

  @doc """
  Obtiene el historial de compras de un cliente.
  """
  def historial_compras_cliente(cliente_id) do
    obtener_todos_los_servidores()
    |> Enum.flat_map(fn {_id, pid} ->
      case ServidorSorteo.compras_cliente(pid, cliente_id) do
        {:ok, compras} -> compras
        _ -> []
      end
    end)
  end

  @doc """
  Obtiene los premios ganados por un cliente.
  """
  def premios_cliente(cliente_id) do
    obtener_todos_los_servidores()
    |> Enum.flat_map(fn {_id, pid} ->
      case ServidorSorteo.premios_ganados_cliente(pid, cliente_id) do
        {:ok, premios} -> premios
        _ -> []
      end
    end)
  end

  @doc """
  Devuelve una compra si el sorteo no se ha realizado.
  """
  def devolver_compra(cliente_id, compra_id) do
    resultado =
      obtener_todos_los_servidores()
      |> Enum.find_value(fn {_id, pid} ->
        case ServidorSorteo.devolver_compra(pid, cliente_id, compra_id) do
          {:ok, _} = result -> result
          _ -> nil
        end
      end)

    resultado || {:error, :compra_no_encontrada}
  end

  @doc """
  Calcula el balance general de todos los sorteos realizados.
  """
  def balance_general do
    sorteos_realizados =
      listar_sorteos()
      |> Enum.filter(fn s -> s.estado == :realizado end)

    balances =
      Enum.map(sorteos_realizados, fn sorteo ->
        case obtener_servidor(sorteo.id) do
          {:ok, pid} ->
            {:ok, balance} = ServidorSorteo.balance(pid)
            Map.put(balance, :sorteo, sorteo)

          _ ->
            nil
        end
      end)
      |> Enum.filter(&(&1 != nil))

    total_ingresos = Enum.reduce(balances, 0, fn b, acc -> acc + b.ingresos end)
    total_premios = Enum.reduce(balances, 0, fn b, acc -> acc + b.premios_entregados end)

    {:ok,
     %{
       sorteos: balances,
       total_ingresos: total_ingresos,
       total_premios_entregados: total_premios,
       balance_total: total_ingresos - total_premios
     }}
  end

  # ============================================================================
  # Funciones Privadas
  # ============================================================================

  defp iniciar_servidor_sorteo(sorteo) do
    spec = {ServidorSorteo, sorteo}
    DynamicSupervisor.start_child(@name, spec)
  end

  defp obtener_todos_los_servidores do
    Registry.select(AzarSa.SorteoRegistry, [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  end

  defp cargar_sorteos_desde_archivo do
    case Store.cargar_sorteos() do
      {:ok, sorteos} ->
        Enum.each(sorteos, fn sorteo_map ->
          sorteo = Sorteo.from_map(sorteo_map)
          iniciar_servidor_sorteo(sorteo)
        end)

        Logger.info("#{length(sorteos)} sorteos cargados desde archivo")

      {:error, _} ->
        Logger.info("No se encontraron sorteos previos, iniciando limpio")
    end
  end
end
