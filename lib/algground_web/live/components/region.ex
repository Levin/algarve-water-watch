defmodule AlggroundWeb.Components.Region do
  use AlggroundWeb, :live_component

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{region: region}, socket) do
    {:ok,
     socket
     |> assign(:region, region)}
  end

  # <img src={@region.image} class="absolute h-14 left-0 top-9 " />
  def render(assigns) do
    ~H"""
    <div
      phx-click="select_municipality"
      phx-value-municipality={@region.municipality}
      class="py-4 cursor-pointer text-center text-base font-semibold text-indigo-800 mb-2 bg-gray-50 rounded-lg"
    >
      <%= display_region(assigns) %>

      <div id={"information_" <> @region.municipality} class="hidden">
        <div class=" mb-8">
          <div class="px-8 pt-8 sm:px-10 sm:pt-10">
            <p class="mt-2 text-md font-medium tracking-tight text-gray-600 max-lg:text-center">
              Ground Water Level
            </p>
            <p class="mt-2 max-w-lg text-lg/6 text-gray-600 max-lg:text-center">
              <%= display_groundwater(assigns) %>
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp display_region(assigns) do
    Enum.random([
      ~H"""
      <p class="mt-2 max-w-lg text-lg/6 text-green-600 max-lg:text-center">
        <%= @region.municipality %>
      </p>
      """
    ])
  end

  defp display_groundwater(assigns) do
    cond do
      assigns.region.groundwater_levels >= 150 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-green-600 max-lg:text-center">
          <%= @region.groundwater_levels %>cm
        </p>
        """

      assigns.region.groundwater_levels < 150 and assigns.region.groundwater_levels >= 50 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-amber-500 max-lg:text-center">
          <%= @region.groundwater_levels %>cm
        </p>
        """

      assigns.region.groundwater_levels < 50 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-red-600 max-lg:text-center">
          <%= @region.groundwater_levels %>cm
        </p>
        """
    end
  end

end
