defmodule BiteBeaconWeb.RedirectPlug do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _default) do
    conn
    |> Phoenix.Controller.redirect(to: "/users/log_in")
    |> halt()
  end
end
