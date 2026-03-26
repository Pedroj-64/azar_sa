defmodule AzarSa.Data.Store do
  @moduledoc """
  Módulo de persistencia de datos usando archivos JSON.

  Almacena todos los datos del sistema en archivos JSON ubicados
  en `priv/data/`:

  - sorteos.json - Lista de sorteos
  - clientes.json - Lista de clientes registrados  
  - sorteos/{id}.json - Datos completos de cada sorteo (premios y compras)
  """

  @data_dir "priv/data"
  @sorteos_file "sorteos.json"
  @clientes_file "clientes.json"
  @sorteos_dir "sorteos"

  # ============================================================================
  # Funciones de Sorteos
  # ============================================================================

  @doc """
  Carga la lista de sorteos desde el archivo.
  """
  def cargar_sorteos do
    read_json(sorteos_path())
  end

  @doc """
  Guarda la lista de sorteos en el archivo.
  """
  def guardar_sorteos(sorteos) do
    write_json(sorteos_path(), sorteos)
  end

  @doc """
  Carga los datos completos de un sorteo (sorteo + premios + compras).
  """
  def cargar_sorteo_completo(sorteo_id) do
    read_json(sorteo_path(sorteo_id))
  end

  @doc """
  Guarda los datos completos de un sorteo.
  """
  def guardar_sorteo_completo(sorteo_id, data) do
    # También actualizar la lista de sorteos
    actualizar_lista_sorteos(data["sorteo"])
    write_json(sorteo_path(sorteo_id), data)
  end

  @doc """
  Elimina un sorteo y sus datos.
  """
  def eliminar_sorteo(sorteo_id) do
    # Eliminar archivo individual
    path = sorteo_path(sorteo_id)
    File.rm(path)

    # Actualizar lista de sorteos
    case cargar_sorteos() do
      {:ok, sorteos} ->
        nuevos_sorteos = Enum.reject(sorteos, &(&1["id"] == sorteo_id))
        guardar_sorteos(nuevos_sorteos)

      _ ->
        :ok
    end
  end

  # ============================================================================
  # Funciones de Clientes
  # ============================================================================

  @doc """
  Carga la lista de clientes.
  """
  def cargar_clientes do
    read_json(clientes_path())
  end

  @doc """
  Guarda la lista de clientes.
  """
  def guardar_clientes(clientes) do
    write_json(clientes_path(), clientes)
  end

  @doc """
  Agrega o actualiza un cliente.
  """
  def guardar_cliente(cliente_map) do
    case cargar_clientes() do
      {:ok, clientes} ->
        nuevos_clientes = upsert_by_id(clientes, cliente_map)
        guardar_clientes(nuevos_clientes)

      {:error, _} ->
        guardar_clientes([cliente_map])
    end
  end

  @doc """
  Obtiene un cliente por su ID.
  """
  def obtener_cliente(cliente_id) do
    case cargar_clientes() do
      {:ok, clientes} ->
        case Enum.find(clientes, &(&1["id"] == cliente_id)) do
          nil -> {:error, :no_encontrado}
          cliente -> {:ok, cliente}
        end

      error ->
        error
    end
  end

  @doc """
  Obtiene un cliente por su documento.
  """
  def obtener_cliente_por_documento(documento) do
    case cargar_clientes() do
      {:ok, clientes} ->
        case Enum.find(clientes, &(&1["documento"] == documento)) do
          nil -> {:error, :no_encontrado}
          cliente -> {:ok, cliente}
        end

      error ->
        error
    end
  end

  # ============================================================================
  # Funciones de Datos de Prueba
  # ============================================================================

  @doc """
  Inicializa datos de prueba si no existen.
  """
  def inicializar_datos_prueba do
    ensure_data_directory()

    # Solo inicializar si no hay datos
    unless File.exists?(clientes_path()) do
      crear_datos_prueba()
    end
  end

  defp crear_datos_prueba do
    # Clientes de prueba
    clientes = [
      %{
        "id" => "cliente_001",
        "nombre" => "Juan Pérez",
        "documento" => "1234567890",
        "password_hash" => hash_password("123456"),
        "tarjeta_credito" => %{
          "numero" => "4111111111111111",
          "cvv" => "123",
          "vencimiento" => "12/28"
        },
        "notificaciones" => [],
        "created_at" => "2026-01-01T00:00:00Z",
        "updated_at" => "2026-01-01T00:00:00Z"
      },
      %{
        "id" => "cliente_002",
        "nombre" => "María García",
        "documento" => "0987654321",
        "password_hash" => hash_password("123456"),
        "tarjeta_credito" => %{
          "numero" => "4222222222222222",
          "cvv" => "456",
          "vencimiento" => "06/27"
        },
        "notificaciones" => [],
        "created_at" => "2026-01-15T00:00:00Z",
        "updated_at" => "2026-01-15T00:00:00Z"
      },
      %{
        "id" => "cliente_003",
        "nombre" => "Carlos López",
        "documento" => "5555555555",
        "password_hash" => hash_password("123456"),
        "tarjeta_credito" => %{
          "numero" => "4333333333333333",
          "cvv" => "789",
          "vencimiento" => "03/29"
        },
        "notificaciones" => [],
        "created_at" => "2026-02-01T00:00:00Z",
        "updated_at" => "2026-02-01T00:00:00Z"
      }
    ]

    guardar_clientes(clientes)

    # Sorteos de prueba
    sorteos = [
      %{
        "id" => "sorteo_001",
        "nombre" => "Lotería de Medellín",
        "fecha" => "2026-04-15",
        "valor_billete" => 50000,
        "cantidad_fracciones" => 5,
        "cantidad_billetes" => 1000,
        "estado" => "pendiente",
        "numeros_ganadores" => [],
        "premios" => ["premio_001", "premio_002"],
        "created_at" => "2026-03-01T00:00:00Z",
        "updated_at" => "2026-03-01T00:00:00Z"
      },
      %{
        "id" => "sorteo_002",
        "nombre" => "Lotería de Bogotá",
        "fecha" => "2026-04-20",
        "valor_billete" => 75000,
        "cantidad_fracciones" => 10,
        "cantidad_billetes" => 2000,
        "estado" => "pendiente",
        "numeros_ganadores" => [],
        "premios" => ["premio_003"],
        "created_at" => "2026-03-05T00:00:00Z",
        "updated_at" => "2026-03-05T00:00:00Z"
      },
      %{
        "id" => "sorteo_003",
        "nombre" => "Lotería del Valle",
        "fecha" => "2026-03-10",
        "valor_billete" => 30000,
        "cantidad_fracciones" => 3,
        "cantidad_billetes" => 500,
        "estado" => "realizado",
        "numeros_ganadores" => [
          %{
            "premio_id" => "premio_004",
            "premio_nombre" => "Premio Mayor",
            "numero" => 123,
            "valor" => 100_000_000
          }
        ],
        "premios" => ["premio_004"],
        "created_at" => "2026-02-15T00:00:00Z",
        "updated_at" => "2026-03-10T00:00:00Z"
      }
    ]

    guardar_sorteos(sorteos)

    # Datos completos de cada sorteo
    guardar_sorteo_completo("sorteo_001", %{
      "sorteo" => Enum.at(sorteos, 0),
      "premios" => [
        %{
          "id" => "premio_001",
          "sorteo_id" => "sorteo_001",
          "nombre" => "Premio Mayor",
          "valor" => 500_000_000,
          "numero_ganador" => nil,
          "ganadores" => [],
          "created_at" => "2026-03-01T00:00:00Z"
        },
        %{
          "id" => "premio_002",
          "sorteo_id" => "sorteo_001",
          "nombre" => "Segundo Premio",
          "valor" => 100_000_000,
          "numero_ganador" => nil,
          "ganadores" => [],
          "created_at" => "2026-03-01T00:00:00Z"
        }
      ],
      "compras" => [
        %{
          "id" => "compra_001",
          "cliente_id" => "cliente_001",
          "sorteo_id" => "sorteo_001",
          "numero" => 777,
          "tipo" => "billete_completo",
          "fracciones" => [1, 2, 3, 4, 5],
          "valor_pagado" => 50000,
          "estado" => "activa",
          "premio_obtenido" => nil,
          "created_at" => "2026-03-10T00:00:00Z"
        },
        %{
          "id" => "compra_002",
          "cliente_id" => "cliente_002",
          "sorteo_id" => "sorteo_001",
          "numero" => 123,
          "tipo" => "fraccion",
          "fracciones" => [1, 2],
          "valor_pagado" => 20000,
          "estado" => "activa",
          "premio_obtenido" => nil,
          "created_at" => "2026-03-11T00:00:00Z"
        }
      ]
    })

    guardar_sorteo_completo("sorteo_002", %{
      "sorteo" => Enum.at(sorteos, 1),
      "premios" => [
        %{
          "id" => "premio_003",
          "sorteo_id" => "sorteo_002",
          "nombre" => "Premio Mayor",
          "valor" => 1_000_000_000,
          "numero_ganador" => nil,
          "ganadores" => [],
          "created_at" => "2026-03-05T00:00:00Z"
        }
      ],
      "compras" => []
    })

    guardar_sorteo_completo("sorteo_003", %{
      "sorteo" => Enum.at(sorteos, 2),
      "premios" => [
        %{
          "id" => "premio_004",
          "sorteo_id" => "sorteo_003",
          "nombre" => "Premio Mayor",
          "valor" => 100_000_000,
          "numero_ganador" => 123,
          "ganadores" => [
            %{
              "cliente_id" => "cliente_003",
              "tipo" => "billete_completo",
              "fracciones" => [1, 2, 3]
            }
          ],
          "created_at" => "2026-02-15T00:00:00Z"
        }
      ],
      "compras" => [
        %{
          "id" => "compra_003",
          "cliente_id" => "cliente_003",
          "sorteo_id" => "sorteo_003",
          "numero" => 123,
          "tipo" => "billete_completo",
          "fracciones" => [1, 2, 3],
          "valor_pagado" => 30000,
          "estado" => "ganadora",
          "premio_obtenido" => 100_000_000,
          "created_at" => "2026-02-20T00:00:00Z"
        }
      ]
    })

    IO.puts("Datos de prueba inicializados correctamente")
  end

  # ============================================================================
  # Funciones Privadas
  # ============================================================================

  defp read_json(path) do
    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} -> {:ok, data}
          error -> error
        end

      {:error, :enoent} ->
        {:error, :archivo_no_existe}

      error ->
        error
    end
  end

  defp write_json(path, data) do
    ensure_data_directory()
    content = Jason.encode!(data, pretty: true)
    File.write!(path, content)
    :ok
  end

  defp ensure_data_directory do
    File.mkdir_p!(data_dir())
    File.mkdir_p!(Path.join(data_dir(), @sorteos_dir))
  end

  defp data_dir do
    Path.join(File.cwd!(), @data_dir)
  end

  defp sorteos_path do
    Path.join(data_dir(), @sorteos_file)
  end

  defp clientes_path do
    Path.join(data_dir(), @clientes_file)
  end

  defp sorteo_path(sorteo_id) do
    Path.join([data_dir(), @sorteos_dir, "#{sorteo_id}.json"])
  end

  defp upsert_by_id(list, item) do
    id = item["id"]

    case Enum.find_index(list, &(&1["id"] == id)) do
      nil -> [item | list]
      index -> List.replace_at(list, index, item)
    end
  end

  defp actualizar_lista_sorteos(sorteo_map) do
    case cargar_sorteos() do
      {:ok, sorteos} ->
        nuevos_sorteos = upsert_by_id(sorteos, sorteo_map)
        guardar_sorteos(nuevos_sorteos)

      {:error, _} ->
        guardar_sorteos([sorteo_map])
    end
  end

  defp hash_password(password) do
    :crypto.hash(:sha256, password) |> Base.encode16(case: :lower)
  end
end
