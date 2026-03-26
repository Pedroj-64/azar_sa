defmodule AzarSaWeb.SessionController do
  use AzarSaWeb, :controller

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Sesión cerrada correctamente")
    |> redirect(to: "/")
  end
end
