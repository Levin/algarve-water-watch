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
      phx-click={JS.toggle(to: "#information_#{@region}")}
      class="cursor-pointer text-center text-base font-semibold text-indigo-800 mb-2 bg-gray-50 rounded-lg "
    >
      <%= @region %>

      <div id={"information_" <> @region} class="hidden">
        <div class=" mb-8">
          <div class="px-8 pt-8 sm:px-10 sm:pt-10">
            <p class="mt-2 text-md font-medium tracking-tight text-gray-950 max-lg:text-center">
              Rainfall
            </p>
            <p class="mt-2 max-w-lg text-lg/6 text-gray-600 max-lg:text-center text-indigo-800">
              40mm
            </p>
          </div>
          <div class="px-8 pt-8 sm:px-10 sm:pt-10">
            <p class="mt-2 text-md font-medium tracking-tight text-gray-950 max-lg:text-center">
              Reservoirs
            </p>
            <p class="mt-2 max-w-lg text-lg/6 text-gray-600 max-lg:text-center text-indigo-800">
              200.000.000.000l
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
