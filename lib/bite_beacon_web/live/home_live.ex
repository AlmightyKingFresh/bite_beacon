defmodule BiteBeaconWeb.HomeLive do
  use Phoenix.LiveView
  use BiteBeaconWeb, :verified_routes

  def mount(_params, _session, socket) do
    {:ok, socket, layout: false}
  end
end
