defmodule AlggroundWeb.SearchBar do
  use AlggroundWeb, :live_component

  def update(%{regions: regions}, socket) do
    {:ok,
     socket
     |> assign(:regions, regions)
     |> assign(:found_regions, [])}
  end

  def handle_event("search_region", %{"region" => region}, socket) do
    regions =
      case Enum.filter(
             socket.assigns.regions,
             fn stored_region ->
               String.contains?(stored_region.region, region)
             end
           ) do
        [] -> socket.assigns.regions
        filtered -> filtered
      end

    {:noreply,
     socket
     |> assign(:regions, regions)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="mb-4">
        <.simple_form for={%{}} phx-target={@myself} phx-change="search_region">
          <.input type="text" name="region" value="" class="" placeholder="where are you going ?" />
        </.simple_form>
      </div>
      <%= for region <- @regions do %>
        <.live_component
          module={AlggroundWeb.Components.Region}
          region={region}
          id={region.region <> "#{System.unique_integer()}"}
        />
      <% end %>
    </div>
    """
  end
end
