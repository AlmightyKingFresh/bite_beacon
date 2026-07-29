defmodule BiteBeaconWeb.UserLoginLive do
  use BiteBeaconWeb, :live_view

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end

  # <div class="bg">
  #   <svg viewBox="165 35 500 500" class="hero-svg">
  #     <path id="curve" d="M73.2,148.6c4-6.1,65.5-96.8,178.6-95.6c111.3,1.2,170.8,90.3,175.1,97" />
  #     <text>
  #       <textPath xlink:href="#curve" startOffset="50%" text-anchor="middle">
  #         Bite Beacon
  #       </textPath>
  #     </text>
  #   </svg>
end
