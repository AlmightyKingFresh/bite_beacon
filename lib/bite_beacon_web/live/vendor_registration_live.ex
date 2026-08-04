defmodule BiteBeaconWeb.VendorRegistrationLive do
  use BiteBeaconWeb, :live_view

  alias BiteBeacon.Vendors.{Vendor, Vendors}

  def mount(_params, _session, socket) do
    changeset = Vendors.change_vendor_registration(%Vendor{})
    IO.inspect(socket.view)

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"vendor" => vendor_params}, socket) do
    case Vendors.register_vendor(vendor_params) do
      {:ok, vendor} ->
        {:ok, _} =
          Vendors.deliver_vendor_confirmation_instructions(
            vendor,
            &url(~p"/vendors/confirm/#{&1}")
          )

        changeset = Vendors.change_vendor_registration(vendor)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"vendor" => vendor_params}, socket) do
    changeset = Vendors.change_vendor_registration(%Vendor{}, vendor_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "vendor")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
