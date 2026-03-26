defmodule AzarSaWeb.Router do
  use AzarSaWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {AzarSaWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # Pipeline para autenticación de jugadores
  pipeline :jugador_auth do
    plug(AzarSaWeb.Plugs.JugadorAuth)
  end

  # ============================================================================
  # Rutas Públicas
  # ============================================================================

  scope "/", AzarSaWeb do
    pipe_through(:browser)

    get("/", PageController, :home)

    # Autenticación de jugadores (rutas públicas)
    live("/registro", Jugador.RegistroLive, :new)
    live("/login", Jugador.LoginLive, :new)
    delete("/logout", SessionController, :delete)
  end

  # ============================================================================
  # Panel de Administrador
  # ============================================================================

  scope "/admin", AzarSaWeb.Admin, as: :admin do
    pipe_through(:browser)

    live("/", DashboardLive, :index)

    # Gestión de Sorteos
    live("/sorteos", SorteosLive, :index)
    live("/sorteos/nuevo", SorteosLive, :new)
    live("/sorteos/:id", SorteoLive, :show)
    live("/sorteos/:id/editar", SorteoLive, :edit)

    # Gestión de Premios
    live("/premios", PremiosLive, :index)
    live("/sorteos/:sorteo_id/premios/nuevo", PremiosLive, :new)

    # Consultas
    live("/clientes", ClientesLive, :index)
    live("/balance", BalanceLive, :index)
    live("/bitacora", BitacoraLive, :index)

    # Sistema
    live("/sistema", SistemaLive, :index)
  end

  # ============================================================================
  # Panel de Jugadores
  # ============================================================================

  scope "/jugador", AzarSaWeb.Jugador, as: :jugador do
    pipe_through([:browser, :jugador_auth])

    live("/", DashboardLive, :index)

    # Sorteos disponibles
    live("/sorteos", SorteosLive, :index)
    live("/sorteos/:id", SorteoLive, :show)
    live("/sorteos/:id/comprar", CompraLive, :new)

    # Mis compras
    live("/compras", ComprasLive, :index)

    # Mis premios
    live("/premios", PremiosLive, :index)

    # Balance
    live("/balance", BalanceLive, :index)

    # Notificaciones
    live("/notificaciones", NotificacionesLive, :index)
  end

  # ============================================================================
  # API (opcional para clientes externos)
  # ============================================================================

  # API routes - TODO: implement controllers if needed
  # scope "/api", AzarSaWeb.Api do
  #   pipe_through(:api)
  #
  #   # Sorteos
  #   get("/sorteos", SorteoController, :index)
  #   get("/sorteos/:id", SorteoController, :show)
  #
  #   # Autenticación
  #   post("/auth/login", AuthController, :login)
  #   post("/auth/registro", AuthController, :registro)
  # end
end
