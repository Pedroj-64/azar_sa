defmodule AzarSa.Bitacora.Logger do
  @moduledoc """
  Sistema de Bitácora para registrar todas las operaciones.

  Registra cada solicitud con:
  - Fecha y hora
  - Tipo de operación
  - Resultado (ok o negado)

  Los registros se muestran en pantalla y se guardan en archivo.
  """

  use GenServer
  require Logger

  @name __MODULE__
  @log_file "priv/data/bitacora.log"

  # ============================================================================
  # API Pública
  # ============================================================================

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @doc """
  Registra una operación en la bitácora.

  ## Parámetros
  - tipo: Tipo de operación (string)
  - detalle: Descripción de la operación
  - resultado: :ok | :negado | {:ok, _} | {:error, _}
  """
  def registrar(tipo, detalle, resultado) do
    GenServer.cast(@name, {:registrar, tipo, detalle, resultado})
  end

  @doc """
  Obtiene los últimos N registros de la bitácora.
  """
  def obtener_ultimos(n \\ 100) do
    GenServer.call(@name, {:obtener_ultimos, n})
  end

  @doc """
  Limpia la bitácora.
  """
  def limpiar do
    GenServer.call(@name, :limpiar)
  end

  # ============================================================================
  # Callbacks del GenServer
  # ============================================================================

  @impl true
  def init(_state) do
    # Asegurar que el directorio existe
    ensure_log_directory()

    Logger.info("Sistema de Bitácora iniciado")
    {:ok, %{registros: []}}
  end

  @impl true
  def handle_cast({:registrar, tipo, detalle, resultado}, state) do
    timestamp = DateTime.utc_now()
    estado = parse_resultado(resultado)

    registro = %{
      fecha: DateTime.to_date(timestamp) |> Date.to_iso8601(),
      hora: DateTime.to_time(timestamp) |> Time.to_iso8601(),
      timestamp: DateTime.to_iso8601(timestamp),
      tipo: tipo,
      detalle: detalle,
      resultado: estado
    }

    # Mostrar en pantalla
    mostrar_en_pantalla(registro)

    # Guardar en archivo
    guardar_en_archivo(registro)

    # Mantener en memoria (últimos 1000)
    nuevos_registros = [registro | state.registros] |> Enum.take(1000)

    {:noreply, %{state | registros: nuevos_registros}}
  end

  @impl true
  def handle_call({:obtener_ultimos, n}, _from, state) do
    registros = Enum.take(state.registros, n)
    {:reply, registros, state}
  end

  @impl true
  def handle_call(:limpiar, _from, _state) do
    File.write!(log_file_path(), "")
    {:reply, :ok, %{registros: []}}
  end

  # ============================================================================
  # Funciones Privadas
  # ============================================================================

  defp parse_resultado(:ok), do: "OK"
  defp parse_resultado({:ok, _}), do: "OK"
  defp parse_resultado(:negado), do: "NEGADO"
  defp parse_resultado({:error, _}), do: "NEGADO"
  defp parse_resultado(_), do: "OK"

  defp mostrar_en_pantalla(registro) do
    color = if registro.resultado == "OK", do: :green, else: :red

    mensaje =
      "[#{registro.fecha} #{registro.hora}] #{registro.tipo}: #{registro.detalle} - #{registro.resultado}"

    IO.puts(IO.ANSI.format([color, mensaje]))
  end

  defp guardar_en_archivo(registro) do
    linea =
      "#{registro.fecha} - #{registro.hora} - #{registro.tipo} - #{registro.detalle} - #{registro.resultado}\n"

    File.write!(log_file_path(), linea, [:append])
  end

  defp ensure_log_directory do
    path = log_file_path()
    dir = Path.dirname(path)
    File.mkdir_p!(dir)

    unless File.exists?(path) do
      File.write!(
        path,
        "# Bitácora Azar S.A.\n# Fecha - Hora - Operación - Detalle - Resultado\n\n"
      )
    end
  end

  defp log_file_path do
    Path.join(Application.app_dir(:azar_sa), @log_file)
  rescue
    _ -> Path.join(File.cwd!(), @log_file)
  end
end
