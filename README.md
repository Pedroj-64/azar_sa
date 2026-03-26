# Azar S.A. - Sistema de Lotería Distribuido

Sistema distribuido de gestión de sorteos, clientes y apuestas desarrollado en **Elixir** con **Phoenix Framework**.

## Proyecto - Programación III

Este proyecto implementa un sistema completo de lotería con arquitectura distribuida usando las características de concurrencia de Elixir (procesos, mensajes, supervisores).

## Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                    SERVIDOR CENTRAL                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   ServidorCentral                         │   │
│  │  (Punto de entrada - Redirige solicitudes)               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│              ┌───────────────┼───────────────┐                  │
│              ▼               ▼               ▼                  │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐        │
│  │ServidorSorteo │ │ServidorSorteo │ │ServidorSorteo │        │
│  │   Lotería 1   │ │   Lotería 2   │ │   Lotería N   │        │
│  └───────────────┘ └───────────────┘ └───────────────┘        │
│         │                  │                  │                  │
│         └──────────────────┴──────────────────┘                  │
│                            │                                     │
│              ┌─────────────┴─────────────┐                      │
│              ▼                           ▼                      │
│     ┌─────────────┐              ┌─────────────┐               │
│     │  Bitácora   │              │Notificaciones│               │
│     │   (Log)     │              │  (PubSub)    │               │
│     └─────────────┘              └─────────────┘               │
└─────────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Cliente Admin  │  │ Cliente Jugador │  │ Cliente Jugador │
│   (Phoenix)     │  │   (Phoenix)     │  │   (Phoenix)     │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## Componentes Principales

### 1. Servidor Central (`AzarSa.Servidores.ServidorCentral`)
- Punto de entrada para todas las solicitudes
- Redirige a servidores especializados por sorteo
- Registra operaciones en la bitácora

### 2. Servidor de Sorteo (`AzarSa.Servidores.ServidorSorteo`)
- Un GenServer por cada sorteo
- Maneja información, premios y compras
- Ejecuta el sorteo y asigna ganadores

### 3. Sistema de Bitácora (`AzarSa.Bitacora.Logger`)
- Registra todas las operaciones (fecha, hora, resultado)
- Muestra en pantalla y guarda en archivo

### 4. Sistema de Notificaciones (`AzarSa.Notificaciones.Servidor`)
- Envía notificaciones a ganadores
- Usa Phoenix.PubSub para tiempo real

## Instalación

### Requisitos
- Elixir 1.14+
- Erlang/OTP 24+

### Setup

```bash
# Clonar o navegar al proyecto
cd /home/ajolote/Documentos/Codigo/azar_sa

# Ejecutar setup
./scripts/setup.sh

# O manualmente:
mix deps.get
mix compile
mix assets.setup
```

## Ejecución

### Servidor de Desarrollo

```bash
./scripts/dev.sh

# O manualmente:
mix phx.server
```

El servidor estará disponible en: http://localhost:4000

### Accesos

| Aplicación | URL | Descripción |
|------------|-----|-------------|
| Panel Admin | http://localhost:4000/admin | Gestión de sorteos y premios |
| Login Jugador | http://localhost:4000/login | Acceso para jugadores |
| Registro | http://localhost:4000/registro | Registro de nuevos jugadores |

### Usuarios de Prueba

| Documento | Contraseña | Nombre |
|-----------|------------|--------|
| 1234567890 | 123456 | Juan Pérez |
| 0987654321 | 123456 | María García |
| 5555555555 | 123456 | Carlos López |

## Scripts Disponibles

| Script | Descripción |
|--------|-------------|
| `./scripts/dev.sh` | Inicia servidor de desarrollo |
| `./scripts/tunnel.sh` | Crea túnel de Cloudflare para URL pública |
| `./scripts/test.sh` | Ejecuta tests |
| `./scripts/console.sh` | Abre consola IEx interactiva |
| `./scripts/setup.sh` | Setup inicial del proyecto |
| `./scripts/build.sh` | Build de producción |
| `./scripts/reset.sh` | Resetea datos de prueba |

### Túnel de Cloudflare

Para exponer el servidor local a internet (útil para pruebas):

```bash
# En una terminal, iniciar servidor
./scripts/dev.sh

# En otra terminal, crear túnel
./scripts/tunnel.sh
```

Esto generará una URL pública tipo: `https://xxx-xxx.trycloudflare.com`

## Estructura del Proyecto

```
azar_sa/
├── lib/
│   ├── azar_sa/
│   │   ├── application.ex          # Configuración OTP
│   │   ├── apuestas/
│   │   │   └── compra.ex           # Modelo de Compra
│   │   ├── bitacora/
│   │   │   └── logger.ex           # Sistema de bitácora
│   │   ├── clientes/
│   │   │   ├── cliente.ex          # Modelo de Cliente
│   │   │   └── clientes.ex         # Contexto de Clientes
│   │   ├── data/
│   │   │   └── store.ex            # Persistencia JSON
│   │   ├── notificaciones/
│   │   │   └── servidor.ex         # Sistema de notificaciones
│   │   ├── premios/
│   │   │   └── premio.ex           # Modelo de Premio
│   │   ├── servidores/
│   │   │   ├── servidor_central.ex # GenServer central
│   │   │   ├── servidor_sorteo.ex  # GenServer por sorteo
│   │   │   └── sorteo_supervisor.ex# DynamicSupervisor
│   │   ├── sistema/
│   │   │   └── fecha.ex            # Sistema de fecha simulada
│   │   └── sorteos/
│   │       └── sorteo.ex           # Modelo de Sorteo
│   └── azar_sa_web/
│       ├── live/
│       │   ├── admin/              # LiveViews de administrador
│       │   └── jugador/            # LiveViews de jugadores
│       └── router.ex               # Rutas
├── priv/
│   └── data/                       # Datos JSON
│       ├── clientes.json
│       ├── sorteos.json
│       ├── sorteos/                # Datos por sorteo
│       └── bitacora.log
├── scripts/                        # Scripts de utilidad
└── docs/                           # Documentación adicional
```

## Funcionalidades

### Panel de Administrador

#### Gestión de Sorteos
- Crear sorteo (nombre, fecha, valor, fracciones, billetes)
- Listar sorteos ordenados por fecha
- Ver premios y ganadores
- Eliminar sorteo (solo sin premios)
- Consultar clientes por sorteo
- Consultar ingresos

#### Gestión de Premios
- Crear premios para sorteos
- Listar premios agrupados por sorteo
- Eliminar premios (solo sin clientes)

#### Sistema
- Actualizar fecha del sistema
- Ejecutar sorteos pendientes
- Ver bitácora de operaciones
- Consultar balance general

### Panel de Jugadores

- Registro con tarjeta simulada
- Ver sorteos disponibles
- Comprar billetes completos
- Comprar fracciones
- Historial de compras
- Devolver compras (antes del sorteo)
- Ver premios ganados
- Ver balance personal
- Notificaciones de resultados

## Persistencia de Datos

Los datos se almacenan en archivos JSON en `priv/data/`:
- `clientes.json` - Clientes registrados
- `sorteos.json` - Lista de sorteos
- `sorteos/{id}.json` - Datos completos por sorteo
- `bitacora.log` - Registro de operaciones

## Tecnologías

- **Elixir** - Lenguaje de programación
- **Phoenix Framework** - Framework web
- **Phoenix LiveView** - UI en tiempo real
- **GenServer/Supervisor** - Concurrencia OTP
- **Tailwind CSS** - Estilos
- **JSON** - Persistencia de datos

## Conceptos de Elixir Aplicados

1. **GenServer** - Servidores de estado para sorteos
2. **DynamicSupervisor** - Supervisión de procesos dinámicos
3. **Registry** - Registro de procesos por ID
4. **PubSub** - Comunicación entre procesos
5. **Structs** - Modelado de datos
6. **Pattern Matching** - Manejo de mensajes

## Autor

Proyecto de Programación III - Elixir

## Licencia

Uso educativo
