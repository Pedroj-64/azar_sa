defmodule AzarSa.Sorteos.Sorteo do
  @moduledoc """
  Estructura de datos para representar un Sorteo.

  Un sorteo contiene:
  - id: Identificador único
  - nombre: Nombre del sorteo
  - fecha: Fecha programada del sorteo
  - valor_billete: Valor del billete completo
  - cantidad_fracciones: Número de fracciones por billete
  - cantidad_billetes: Total de billetes disponibles
  - estado: :pendiente | :realizado | :cancelado
  - numeros_ganadores: Lista de números ganadores (después del sorteo)
  - premios: Lista de premios asociados
  """

  @derive Jason.Encoder
  defstruct [
    :id,
    :nombre,
    :fecha,
    :valor_billete,
    :cantidad_fracciones,
    :cantidad_billetes,
    :estado,
    :numeros_ganadores,
    :premios,
    :created_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          nombre: String.t(),
          fecha: Date.t() | String.t(),
          valor_billete: number(),
          cantidad_fracciones: pos_integer(),
          cantidad_billetes: pos_integer(),
          estado: :pendiente | :realizado | :cancelado,
          numeros_ganadores: list(map()),
          premios: list(String.t()),
          created_at: DateTime.t() | String.t(),
          updated_at: DateTime.t() | String.t()
        }

  @doc """
  Crea un nuevo sorteo con los parámetros dados.
  """
  def new(attrs) do
    %__MODULE__{
      id: attrs[:id] || generate_id(),
      nombre: attrs[:nombre],
      fecha: parse_date(attrs[:fecha]),
      valor_billete: attrs[:valor_billete],
      cantidad_fracciones: attrs[:cantidad_fracciones] || 1,
      cantidad_billetes: attrs[:cantidad_billetes],
      estado: :pendiente,
      numeros_ganadores: [],
      premios: [],
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  @doc """
  Calcula el valor de una fracción.
  """
  def valor_fraccion(%__MODULE__{valor_billete: valor, cantidad_fracciones: fracciones}) do
    valor / fracciones
  end

  @doc """
  Verifica si el sorteo puede ser eliminado (sin premios asociados).
  """
  def puede_eliminarse?(%__MODULE__{premios: premios}) do
    Enum.empty?(premios)
  end

  @doc """
  Verifica si el sorteo ya fue realizado.
  """
  def realizado?(%__MODULE__{estado: estado}) do
    estado == :realizado
  end

  @doc """
  Convierte el struct a un mapa para serialización JSON.
  """
  def to_map(%__MODULE__{} = sorteo) do
    %{
      id: sorteo.id,
      nombre: sorteo.nombre,
      fecha: to_string(sorteo.fecha),
      valor_billete: sorteo.valor_billete,
      cantidad_fracciones: sorteo.cantidad_fracciones,
      cantidad_billetes: sorteo.cantidad_billetes,
      estado: to_string(sorteo.estado),
      numeros_ganadores: sorteo.numeros_ganadores,
      premios: sorteo.premios,
      created_at: sorteo.created_at,
      updated_at: sorteo.updated_at
    }
  end

  @doc """
  Crea un Sorteo desde un mapa (deserialización JSON).
  """
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      nombre: map["nombre"],
      fecha: parse_date(map["fecha"]),
      valor_billete: map["valor_billete"],
      cantidad_fracciones: map["cantidad_fracciones"],
      cantidad_billetes: map["cantidad_billetes"],
      estado: parse_estado(map["estado"]),
      numeros_ganadores: map["numeros_ganadores"] || [],
      premios: map["premios"] || [],
      created_at: map["created_at"],
      updated_at: map["updated_at"]
    }
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp parse_date(nil), do: nil
  defp parse_date(%Date{} = date), do: date

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      _ -> date_string
    end
  end

  defp parse_estado(nil), do: :pendiente
  defp parse_estado("pendiente"), do: :pendiente
  defp parse_estado("realizado"), do: :realizado
  defp parse_estado("cancelado"), do: :cancelado
  defp parse_estado(estado) when is_atom(estado), do: estado
end
