defmodule AzarSa.Clientes do
  @moduledoc """
  Contexto de Clientes.

  Proporciona funciones para gestionar clientes/jugadores:
  - Registro de usuarios
  - Autenticación
  - Gestión de notificaciones
  """

  alias AzarSa.Clientes.Cliente
  alias AzarSa.Data.Store

  @doc """
  Registra un nuevo cliente.
  """
  def registrar(params) do
    # Verificar que no exista un cliente con el mismo documento
    case Store.obtener_cliente_por_documento(params[:documento]) do
      {:ok, _} ->
        {:error, :documento_ya_registrado}

      {:error, _} ->
        cliente = Cliente.new(params)
        Store.guardar_cliente(Cliente.to_map(cliente))
        {:ok, cliente}
    end
  end

  @doc """
  Autentica un cliente con documento y contraseña.
  """
  def autenticar(documento, password) do
    case Store.obtener_cliente_por_documento(documento) do
      {:ok, cliente_map} ->
        cliente = Cliente.from_map(cliente_map)

        if Cliente.verificar_password(cliente, password) do
          {:ok, cliente}
        else
          {:error, :credenciales_invalidas}
        end

      {:error, _} ->
        {:error, :cliente_no_encontrado}
    end
  end

  @doc """
  Obtiene un cliente por su ID.
  """
  def obtener(cliente_id) do
    case Store.obtener_cliente(cliente_id) do
      {:ok, cliente_map} -> {:ok, Cliente.from_map(cliente_map)}
      error -> error
    end
  end

  @doc """
  Obtiene las notificaciones de un cliente.
  """
  def obtener_notificaciones(cliente_id) do
    case obtener(cliente_id) do
      {:ok, cliente} -> {:ok, cliente.notificaciones}
      error -> error
    end
  end

  @doc """
  Agrega una notificación a un cliente.
  """
  def agregar_notificacion(cliente_id, mensaje) do
    case obtener(cliente_id) do
      {:ok, cliente} ->
        cliente_actualizado = Cliente.agregar_notificacion(cliente, mensaje)
        Store.guardar_cliente(Cliente.to_map(cliente_actualizado))
        {:ok, cliente_actualizado}

      error ->
        error
    end
  end

  @doc """
  Marca una notificación como leída.
  """
  def marcar_notificacion_leida(cliente_id, notificacion_id) do
    case obtener(cliente_id) do
      {:ok, cliente} ->
        cliente_actualizado = Cliente.marcar_notificacion_leida(cliente, notificacion_id)
        Store.guardar_cliente(Cliente.to_map(cliente_actualizado))
        {:ok, cliente_actualizado}

      error ->
        error
    end
  end

  @doc """
  Lista todos los clientes.
  """
  def listar do
    case Store.cargar_clientes() do
      {:ok, clientes} -> Enum.map(clientes, &Cliente.from_map/1)
      {:error, _} -> []
    end
  end
end
