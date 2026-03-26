defmodule AzarSa.Premios.Premio do
  @moduledoc """
  Estructura de datos para representar un Premio.

  Un premio pertenece a un sorteo y tiene:
  - id: Identificador único
  - sorteo_id: ID del sorteo al que pertenece
  - nombre: Nombre del premio (ej: "Premio Mayor", "Segundo Premio")
  - valor: Valor monetario del premio
  - numero_ganador: Número que ganó este premio (después del sorteo)
  - ganadores: Lista de clientes que ganaron
  """

  @derive Jason.Encoder
  defstruct [
    :id,
    :sorteo_id,
    :nombre,
    :valor,
    :numero_ganador,
    :ganadores,
    :created_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          sorteo_id: String.t(),
          nombre: String.t(),
          valor: number(),
          numero_ganador: pos_integer() | nil,
          ganadores: list(map()),
          created_at: String.t()
        }

  @doc """
  Crea un nuevo premio.
  """
  def new(attrs) do
    %__MODULE__{
      id: attrs[:id] || generate_id(),
      sorteo_id: attrs[:sorteo_id],
      nombre: attrs[:nombre],
      valor: attrs[:valor],
      numero_ganador: nil,
      ganadores: [],
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  @doc """
  Convierte el struct a un mapa para serialización JSON.
  """
  def to_map(%__MODULE__{} = premio) do
    %{
      id: premio.id,
      sorteo_id: premio.sorteo_id,
      nombre: premio.nombre,
      valor: premio.valor,
      numero_ganador: premio.numero_ganador,
      ganadores: premio.ganadores,
      created_at: premio.created_at
    }
  end

  @doc """
  Crea un Premio desde un mapa (deserialización JSON).
  """
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      sorteo_id: map["sorteo_id"],
      nombre: map["nombre"],
      valor: map["valor"],
      numero_ganador: map["numero_ganador"],
      ganadores: map["ganadores"] || [],
      created_at: map["created_at"]
    }
  end

  @doc """
  Calcula el valor del premio por fracción.
  """
  def valor_por_fraccion(%__MODULE__{valor: valor}, cantidad_fracciones) do
    valor / cantidad_fracciones
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
