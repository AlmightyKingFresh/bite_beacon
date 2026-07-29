defmodule BiteBeaconWeb.FacilityLive.FormComponent do
  use BiteBeaconWeb, :live_component

  alias BiteBeacon.Food_Facilities

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage facility records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="facility-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <:actions>
          <.button phx-disable-with="Saving...">Save Facility</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{facility: facility} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Food_Facilities.change_facility(facility))
     end)}
  end

  @impl true
  def handle_event("validate", %{"facility" => facility_params}, socket) do
    changeset = Food_Facilities.change_facility(socket.assigns.facility, facility_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"facility" => facility_params}, socket) do
    save_facility(socket, socket.assigns.action, facility_params)
  end

  defp save_facility(socket, :edit, facility_params) do
    case Food_Facilities.update_facility(socket.assigns.facility, facility_params) do
      {:ok, facility} ->
        notify_parent({:saved, facility})

        {:noreply,
         socket
         |> put_flash(:info, "Facility updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_facility(socket, :new, facility_params) do
    case Food_Facilities.create_facility(facility_params) do
      {:ok, facility} ->
        notify_parent({:saved, facility})

        {:noreply,
         socket
         |> put_flash(:info, "Facility created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
