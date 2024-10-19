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

  def render(assigns) do
    ~H"""
    <div
      phx-target={@myself}
      600
      phx-click={JS.toggle(to: "#information_#{@region.region}")}
      class="py-4 cursor-pointer text-center text-base font-semibold text-indigo-800 mb-2 bg-gray-50 rounded-lg"
    >
      <%= display_region(assigns) %>
      <img src={@region.image} class="absolute h-14 left-0 top-9 " />

      <div id={"information_" <> @region.region} class="hidden">
        <div class=" mb-8">
          <div class="px-8 pt-8 sm:px-10 sm:pt-10">
            <p class="mt-2 text-md font-medium tracking-tight text-gray-600 max-lg:text-center">
              Ground Water Level
            </p>
            <p class="mt-2 max-w-lg text-lg/6 text-gray-600 max-lg:text-center">
              <%= display_groundwater(assigns) %>
            </p>
          </div>
          <div class="px-8 pt-8 sm:px-10 sm:pt-10">
            <p class="mt-2 text-md font-medium tracking-tight text-gray-600 max-lg:text-center">
              Rainfall
            </p>
            <p class="mt-2 max-w-lg text-lg/6 text-gray-600 max-lg:text-center text-indigo-800">
              <%= display_rainfall(assigns) %>
            </p>
          </div>
          <div class="px-8 pt-8 sm:px-10 sm:pt-10">
            <p class="mt-2 text-md font-medium tracking-tight text-gray-600 max-lg:text-center">
              Reservoirs
            </p>
            <p class="mt-2 max-w-lg text-lg/6 text-gray-600 max-lg:text-center text-indigo-800">
              <%= display_reservoirs(assigns) %>
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
        <%= @region.region %>
      </p>
      """,
      ~H"""
      <p class="mt-2 max-w-lg text-lg/6 text-amber-500 max-lg:text-center">
        <%= @region.region %>
      </p>
      """,
      ~H"""
      <p class="mt-2 max-w-lg text-lg/6 text-red-600 max-lg:text-center">
        <%= @region.region %>
      </p>
      """
    ])
  end

  defp display_groundwater(assigns) do
    cond do
      assigns.region.groundwater >= 150 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-green-600 max-lg:text-center">
          <%= @region.groundwater %>m
        </p>
        """

      assigns.region.groundwater < 150 and assigns.region.groundwater >= 50 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-amber-500 max-lg:text-center">
          <%= @region.groundwater %>m
        </p>
        """

      assigns.region.groundwater < 50 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-red-600 max-lg:text-center">
          <%= @region.groundwater %>m
        </p>
        """
    end
  end

  defp display_rainfall(assigns) do
    cond do
      assigns.region.rainfall >= 80 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-green-600 max-lg:text-center">
          <%= @region.rainfall %>ml
        </p>
        """

      assigns.region.rainfall < 80 and assigns.region.rainfall >= 30 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-amber-500 max-lg:text-center">
          <%= @region.rainfall %>ml
        </p>
        """

      assigns.region.rainfall < 30 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-red-600 max-lg:text-center">
          <%= @region.rainfall %>ml
        </p>
        """
    end
  end

  defp display_reservoirs(assigns) do
    cond do
      assigns.region.reservoir >= 6_000_000 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-green-600 max-lg:text-center">
          <%= @region.reservoir %> 10⁶m³
        </p>
        """

      assigns.region.reservoir < 6_000_000 and assigns.region.reservoir >= 1_200_000 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-amber-500 max-lg:text-center">
          <%= @region.reservoir %> 10⁶m³
        </p>
        """

      assigns.region.reservoir < 1_200_000 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-red-600 max-lg:text-center">
          <%= @region.reservoir %> 10⁶m³
        </p>
        """
    end
  end
end
