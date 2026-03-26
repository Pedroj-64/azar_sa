defmodule AzarSa.Clientes.Cliente do
  @moduledoc """
  Estructura de datos para representar un Cliente/Jugador.

  Un cliente puede registrarse en el sistema y realizar compras.
  Contiene:
  - id: Identificador único
  - nombre: Nombre completo
  - documento: Número de documento de identidad
  - password_hash: Hash de la contraseña
  - tarjeta_credito: Datos simulados de tarjeta de crédito
  - notificaciones: Lista de notificaciones recibidas
  """

  @derive Jason.Encoder
  defstruct [
    :id,
    :nombre,
    :documento,
    :password_hash,
    :tarjeta_credito,
    :notificaciones,
    :created_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          nombre: String.t(),
          documento: String.t(),
          password_hash: String.t(),
          tarjeta_credito: map(),
          notificaciones: list(map()),
          created_at: String.t(),
          updated_at: String.t()
        }

  @doc """
  Crea un nuevo cliente con los parámetros dados.
  """
  def new(attrs) do
    %__MODULE__{
      id: attrs[:id] || generate_id(),
      nombre: attrs[:nombre],
      documento: attrs[:documento],
      password_hash: hash_password(attrs[:password]),
      tarjeta_credito: attrs[:tarjeta_credito] || %{},
      notificaciones: [],
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  @doc """
  Verifica si la contraseña proporcionada es correcta.
  """
  def verificar_password(%__MODULE__{password_hash: hash}, password) do
    hash_password(password) == hash
  end

  @doc """
  Agrega una notificación al cliente.
  """
  def agregar_notificacion(%__MODULE__{notificaciones: notificaciones} = cliente, notificacion) do
    nueva_notificacion = %{
      id: generate_id(),
      mensaje: notificacion,
      leida: false,
      fecha: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    %{cliente | notificaciones: [nueva_notificacion | notificaciones]}
  end

  @doc """
  Marca una notificación como leída.
  """
  def marcar_notificacion_leida(
        %__MODULE__{notificaciones: notificaciones} = cliente,
        notificacion_id
      ) do
    notificaciones_actualizadas =
      Enum.map(notificaciones, fn notif ->
        if notif.id == notificacion_id or notif["id"] == notificacion_id do
          Map.put(notif, :leida, true) |> Map.put("leida", true)
        else
          notif
        end
      end)

    %{cliente | notificaciones: notificaciones_actualizadas}
  end

  @doc """
  Convierte el struct a un mapa para serialización JSON.
  """
  def to_map(%__MODULE__{} = cliente) do
    %{
      id: cliente.id,
      nombre: cliente.nombre,
      documento: cliente.documento,
      password_hash: cliente.password_hash,
      tarjeta_credito: cliente.tarjeta_credito,
      notificaciones: cliente.notificaciones,
      created_at: cliente.created_at,
      updated_at: cliente.updated_at
    }
  end

  @doc """
  Crea un Cliente desde un mapa (deserialización JSON).
  """
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      nombre: map["nombre"],
      documento: map["documento"],
      password_hash: map["password_hash"],
      tarjeta_credito: map["tarjeta_credito"] || %{},
      notificaciones: map["notificaciones"] || [],
      created_at: map["created_at"],
      updated_at: map["updated_at"]
    }
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp hash_password(nil), do: nil

  defp hash_password(password) do
    :crypto.hash(:sha256, password) |> Base.encode16(case: :lower)
  end
end
