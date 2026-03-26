defmodule AzarSaWeb.Plugs.JugadorAuth do
  @moduledoc """
  Plug para autenticación de jugadores.

  Verifica que exista una sesión válida para acceder
  a las rutas protegidas del panel de jugadores.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :jugador_id) do
      conn
    else
      conn
      |> put_flash(:error, "Debes iniciar sesión para acceder")
      |> redirect(to: "/login")
      |> halt()
    end
  end
end
