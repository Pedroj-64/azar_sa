defmodule AzarSa.Apuestas.Compra do
  @moduledoc """
  Estructura de datos para representar una Compra/Apuesta.

  Una compra puede ser de:
  - Billete completo: Todas las fracciones de un número
  - Fracciones: Una o más fracciones de un número

  Contiene:
  - id: Identificador único
  - cliente_id: ID del cliente que realizó la compra
  - sorteo_id: ID del sorteo
  - numero: Número del billete
  - tipo: :billete_completo | :fraccion
  - fracciones: Lista de fracciones compradas (si es tipo :fraccion)
  - valor_pagado: Monto total pagado
  - estado: :activa | :devuelta | :ganadora | :perdedora
  """

  @derive Jason.Encoder
  defstruct [
    :id,
    :cliente_id,
    :sorteo_id,
    :numero,
    :tipo,
    :fracciones,
    :valor_pagado,
    :estado,
    :premio_obtenido,
    :created_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          cliente_id: String.t(),
          sorteo_id: String.t(),
          numero: pos_integer(),
          tipo: :billete_completo | :fraccion,
          fracciones: list(pos_integer()),
          valor_pagado: number(),
          estado: :activa | :devuelta | :ganadora | :perdedora,
          premio_obtenido: number() | nil,
          created_at: String.t()
        }

  @doc """
  Crea una nueva compra de billete completo.
  """
  def new_billete_completo(attrs) do
    %__MODULE__{
      id: attrs[:id] || generate_id(),
      cliente_id: attrs[:cliente_id],
      sorteo_id: attrs[:sorteo_id],
      numero: attrs[:numero],
      tipo: :billete_completo,
      fracciones: Enum.to_list(1..attrs[:cantidad_fracciones]),
      valor_pagado: attrs[:valor_billete],
      estado: :activa,
      premio_obtenido: nil,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  @doc """
  Crea una nueva compra de fracciones.
  """
  def new_fracciones(attrs) do
    valor_fraccion = attrs[:valor_billete] / attrs[:cantidad_fracciones_total]

    %__MODULE__{
      id: attrs[:id] || generate_id(),
      cliente_id: attrs[:cliente_id],
      sorteo_id: attrs[:sorteo_id],
      numero: attrs[:numero],
      tipo: :fraccion,
      fracciones: attrs[:fracciones],
      valor_pagado: valor_fraccion * length(attrs[:fracciones]),
      estado: :activa,
      premio_obtenido: nil,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  @doc """
  Marca la compra como devuelta.
  """
  def devolver(%__MODULE__{estado: :activa} = compra) do
    {:ok, %{compra | estado: :devuelta}}
  end

  def devolver(_compra), do: {:error, :compra_no_activa}

  @doc """
  Verifica si la compra puede ser devuelta.
  """
  def puede_devolverse?(%__MODULE__{estado: estado}) do
    estado == :activa
  end

  @doc """
  Convierte el struct a un mapa para serialización JSON.
  """
  def to_map(%__MODULE__{} = compra) do
    %{
      id: compra.id,
      cliente_id: compra.cliente_id,
      sorteo_id: compra.sorteo_id,
      numero: compra.numero,
      tipo: to_string(compra.tipo),
      fracciones: compra.fracciones,
      valor_pagado: compra.valor_pagado,
      estado: to_string(compra.estado),
      premio_obtenido: compra.premio_obtenido,
      created_at: compra.created_at
    }
  end

  @doc """
  Crea una Compra desde un mapa (deserialización JSON).
  """
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      cliente_id: map["cliente_id"],
      sorteo_id: map["sorteo_id"],
      numero: map["numero"],
      tipo: parse_tipo(map["tipo"]),
      fracciones: map["fracciones"] || [],
      valor_pagado: map["valor_pagado"],
      estado: parse_estado(map["estado"]),
      premio_obtenido: map["premio_obtenido"],
      created_at: map["created_at"]
    }
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp parse_tipo("billete_completo"), do: :billete_completo
  defp parse_tipo("fraccion"), do: :fraccion
  defp parse_tipo(tipo) when is_atom(tipo), do: tipo

  defp parse_estado("activa"), do: :activa
  defp parse_estado("devuelta"), do: :devuelta
  defp parse_estado("ganadora"), do: :ganadora
  defp parse_estado("perdedora"), do: :perdedora
  defp parse_estado(estado) when is_atom(estado), do: estado
end
