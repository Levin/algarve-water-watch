defmodule AlggroundWeb.LiveHomePage do
  use AlggroundWeb, :live_view

  @region_names [
    %{region: "Albufeira", image: "/images/albufeira.svg"},
    %{region: "Alcoutim", image: ""},
    %{region: "Aljezur", image: ""},
    %{region: "Castro Marim", image: ""},
    %{region: "Faro", image: ""},
    %{region: "Lagoa", image: ""},
    %{region: "Lagos", image: ""},
    %{region: "Monchique", image: ""},
    %{region: "Olhão", image: ""},
    %{region: "Portimão", image: ""},
    %{region: "São Brás de Alportel", image: ""},
    %{region: "Silves", image: ""},
    %{region: "Tavira", image: ""},
    %{region: "Vila do Bispo", image: ""},
    %{region: "Vila Real de Santo António", image: ""}
  ]

  def mount(_params, _session, socket) do
    regions =
      Enum.map(@region_names, fn region ->
        %{
          region: region.region,
          groundwater: trunc(:rand.uniform() * 100),
          rainfall: trunc(:rand.uniform() * 100),
          reservoir: trunc(:rand.uniform() * 1_000),
          image: region.image
        }
      end)

    {:ok,
     socket
     |> assign(:groundwater_levels, Enum.map(regions, & &1.groundwater))
     |> assign(:rainfall_levels, Enum.map(regions, & &1.rainfall))
     |> assign(:reservoir_levels, Enum.map(regions, & &1.reservoir))
     |> assign(:date_start, Datex.Date.today())
     |> assign(:date_end, Datex.Date.add(Datex.Date.today(), 92))
     |> assign(:regions, regions)
     |> assign(:display_groundwater, true)
     |> assign(:display_rainfall, false)
     |> assign(:display_reservoir, false)}
  end

  def handle_event("display_groundwater", _params, socket) do
    {:noreply,
     socket
     |> assign(:display_groundwater, true)
     |> assign(:display_reservoir, false)}
  end

  def handle_event("display_rainfall", _params, socket) do
    {:noreply,
     socket
     |> assign(:display_groundwater, false)
     |> assign(:display_rainfall, true)}
  end

  def handle_event("display_reservoir", _params, socket) do
    {:noreply,
     socket
     |> assign(:display_rainfall, false)
     |> assign(:display_reservoir, true)}
  end

  def handle_event("backward", _params, socket) do
    groundwater = trunc(:rand.uniform() * 100)
    rainfall = trunc(:rand.uniform() * 100)
    reservoir = trunc(:rand.uniform() * 1_000)

    regions =
      Enum.map(@region_names, fn region ->
        %{
          region: region.region,
          groundwater: groundwater,
          rainfall: rainfall,
          reservoir: reservoir,
          image: region.image
        }
      end)

    new_groundwaters = maybe_remove_value([groundwater] ++ socket.assigns.groundwater_levels)
    new_rainfalls = maybe_remove_value([rainfall] ++ socket.assigns.rainfall_levels)
    new_reservoirs = maybe_remove_value([reservoir] ++ socket.assigns.reservoir_levels)

    {:noreply,
     socket
     |> assign(:groundwater_levels, new_groundwaters)
     |> assign(:rainfall_levels, new_rainfalls)
     |> assign(:reservoir_levels, new_reservoirs)
     |> assign(:regions, regions)
     |> assign(:date_start, Datex.Date.add(socket.assigns.date_start, -92))
     |> assign(:date_end, Datex.Date.add(socket.assigns.date_end, -92))}
  end

  def handle_event("forward", _params, socket) do
    groundwater = trunc(:rand.uniform() * 100)
    rainfall = trunc(:rand.uniform() * 100)
    reservoir = trunc(:rand.uniform() * 1_000)

    regions =
      Enum.map(@region_names, fn region ->
        %{
          region: region.region,
          groundwater: groundwater,
          rainfall: rainfall,
          reservoir: reservoir,
          image: region.image
        }
      end)

    new_groundwaters = maybe_add_value(socket.assigns.groundwater_levels ++ [groundwater])
    new_rainfalls = maybe_add_value(socket.assigns.rainfall_levels ++ [rainfall])
    new_reservoirs = maybe_add_value(socket.assigns.reservoir_levels ++ [reservoir])

    {:noreply,
     socket
     |> assign(:groundwater_levels, new_groundwaters)
     |> assign(:rainfall_levels, new_rainfalls)
     |> assign(:reservoir_levels, new_reservoirs)
     |> assign(:regions, regions)
     |> assign(:date_start, Datex.Date.add(socket.assigns.date_start, 92))
     |> assign(:date_end, Datex.Date.add(socket.assigns.date_end, 92))}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="bg-gray-50 py-6 sm:py-6 rounded-lg">
        <div class="mx-auto max-w-2xl px-6 lg:max-w-7xl lg:px-8">
          <div class="flex justify-evenly h-8">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512" phx-click="backward">
              <path d="M9.4 233.4c-12.5 12.5-12.5 32.8 0 45.3l160 160c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3L109.2 288 416 288c17.7 0 32-14.3 32-32s-14.3-32-32-32l-306.7 0L214.6 118.6c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0l-160 160z" />
            </svg>
            <p class="mx-auto max-w-lg text-pretty text-center font-medium tracking-tight text-gray-400 text-3xl">
              <%= Datex.Date.format_date(@date_start, "DD/MM/YYYY") %> to <%= Datex.Date.format_date(
                @date_end,
                "DD/MM/YYYY"
              ) %>
            </p>

            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512" phx-click="forward">
              <path d="M438.6 278.6c12.5-12.5 12.5-32.8 0-45.3l-160-160c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3L338.8 224 32 224c-17.7 0-32 14.3-32 32s14.3 32 32 32l306.7 0L233.4 393.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0l160-160z" />
            </svg>
          </div>
          <p class="mx-auto max-w-lg text-pretty text-center font-medium tracking-tight text-gray-950 text-3xl lg:mt-4 mt-10">
            in <%= get_region(@regions, "Albufeira").region %>
          </p>
          <p class="mx-auto max-w-lg text-pretty text-center text-4xl font-medium tracking-tight sm:text-3xl ">
            <%= display_groundwater(get_region(@regions, "Albufeira")) %>
          </p>
          <div class="flex justify-left ">
            <p class="flex gap-2 mx-auto text-pretty font-sm tracking-tight text-gray-400 text-sm cursor-pointer">
              Ground Water Level
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 320 512"
                class="h-6 w-6 left-2.5 top-2 border rounded-full bg-gray-200 p-1"
                phx-click={show_modal("frame_groundwater")}
              >
                <path d="M80 160c0-35.3 28.7-64 64-64l32 0c35.3 0 64 28.7 64 64l0 3.6c0 21.8-11.1 42.1-29.4 53.8l-42.2 27.1c-25.2 16.2-40.4 44.1-40.4 74l0 1.4c0 17.7 14.3 32 32 32s32-14.3 32-32l0-1.4c0-8.2 4.2-15.8 11-20.2l42.2-27.1c36.6-23.6 58.8-64.1 58.8-107.7l0-3.6c0-70.7-57.3-128-128-128l-32 0C73.3 32 16 89.3 16 160c0 17.7 14.3 32 32 32s32-14.3 32-32zm80 320a40 40 0 1 0 0-80 40 40 0 1 0 0 80z" />
              </svg>
            </p>
          </div>
          <div class="mt-10 grid gap-4 sm:mt-4 lg:rounded-t-[2rem]">
            <div class="relative mb-4">
              <div class="relative flex h-full flex-col overflow-hidden rounded-[calc(2rem+1px)]">
                <.modal id="frame_groundwater"></.modal>
                <.modal id="frame_rainfall"></.modal>
                <.modal id="frame_reservoir"></.modal>
                <div class="flex justify-evenly mb-8">
                  <div class="px-8 pt-8 sm:px-10 sm:pt-10">
                    <p class="flex gap-2 mt-2 text-md font-medium tracking-tight text-gray-950 max-lg:text-center cursor-pointer ">
                      Rainfall
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 320 512"
                        class="h-6 w-6 left-2.5 top-2 border rounded-full bg-gray-200 p-1"
                        phx-click={show_modal("frame_rainfall")}
                      >
                        <path d="M80 160c0-35.3 28.7-64 64-64l32 0c35.3 0 64 28.7 64 64l0 3.6c0 21.8-11.1 42.1-29.4 53.8l-42.2 27.1c-25.2 16.2-40.4 44.1-40.4 74l0 1.4c0 17.7 14.3 32 32 32s32-14.3 32-32l0-1.4c0-8.2 4.2-15.8 11-20.2l42.2-27.1c36.6-23.6 58.8-64.1 58.8-107.7l0-3.6c0-70.7-57.3-128-128-128l-32 0C73.3 32 16 89.3 16 160c0 17.7 14.3 32 32 32s32-14.3 32-32zm80 320a40 40 0 1 0 0-80 40 40 0 1 0 0 80z" />
                      </svg>
                    </p>
                    <p class="mt-2 max-w-lg text-lg/6 text-gray-600 max-lg:text-center">
                      <%= display_rainfall(get_region(@regions, "Albufeira")) %>
                    </p>
                  </div>
                  <div class="px-8 pt-8 sm:px-10 sm:pt-10">
                    <p class="mt-2 text-md font-medium tracking-tight text-gray-950 max-lg:text-center cursor-pointer flex gap-2">
                      Reservoirs
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 320 512"
                        class="h-6 w-6 left-2.5 top-2 border rounded-full bg-gray-200 p-1"
                        phx-click={show_modal("frame_reservoir")}
                      >
                        <path d="M80 160c0-35.3 28.7-64 64-64l32 0c35.3 0 64 28.7 64 64l0 3.6c0 21.8-11.1 42.1-29.4 53.8l-42.2 27.1c-25.2 16.2-40.4 44.1-40.4 74l0 1.4c0 17.7 14.3 32 32 32s32-14.3 32-32l0-1.4c0-8.2 4.2-15.8 11-20.2l42.2-27.1c36.6-23.6 58.8-64.1 58.8-107.7l0-3.6c0-70.7-57.3-128-128-128l-32 0C73.3 32 16 89.3 16 160c0 17.7 14.3 32 32 32s32-14.3 32-32zm80 320a40 40 0 1 0 0-80 40 40 0 1 0 0 80z" />
                      </svg>
                    </p>
                    <p class="mt-2 max-w-lg text-lg/6 text-gray-600 max-lg:text-center">
                      <%= display_reservoirs(get_region(@regions, "Albufeira")) %>
                    </p>
                  </div>
                </div>
              </div>
              <div class="pointer-events-none absolute inset-px rounded-lg shadow ring-1 ring-black/5 max-lg:rounded-t-[2rem]">
              </div>
            </div>
          </div>

          <%= if @display_groundwater do %>
            <div class="rounded-sm bg-white lg:rounded-t-[2rem] px-8 pt-4 contain block md:hidden">
              <%= draw_groundwater(assigns, 280) %>
            </div>
            <div class="rounded-sm bg-white lg:rounded-t-[2rem] px-8 pt-4 contain md:block hidden">
              <%= draw_groundwater(assigns, 580) %>
            </div>
            <div class="flex justify-between px-4">
              <p class="text-md font-medium tracking-tight text-gray-400 max-lg:text-center">
                Ground Water Level
              </p>
              <p phx-click="display_rainfall" class="cursor-pointer">Rainfall</p>
            </div>
          <% end %>
          <%= if @display_rainfall do %>
            <div class="rounded-sm bg-white lg:rounded-t-[2rem] px-8 pt-4 contain block md:hidden">
              <%= draw_rainfall(assigns, 280) %>
            </div>
            <div class="rounded-sm bg-white lg:rounded-t-[2rem] px-8 pt-4 contain md:block hidden">
              <%= draw_rainfall(assigns, 580) %>
            </div>
            <div class="flex justify-between px-4">
              <p class="text-md font-medium tracking-tight text-gray-400 max-lg:text-center">
                Rainfall
              </p>
              <p phx-click="display_reservoir" class="cursor-pointer">Reservoir</p>
            </div>
          <% end %>
          <%= if @display_reservoir do %>
            <div class="rounded-sm bg-white lg:rounded-t-[2rem] px-8 pt-4 block md:hidden">
              <%= draw_reservoir(assigns, 280) %>
            </div>
            <div class="rounded-sm bg-white lg:rounded-t-[2rem] px-8 pt-4 md:block hidden">
              <%= draw_reservoir(assigns, 580) %>
            </div>
            <div class="flex justify-between px-4">
              <p class="text-md font-medium tracking-tight text-gray-400 max-lg:text-center">
                Reservoir Water Level
              </p>
              <p phx-click="display_groundwater" class="cursor-pointer">Ground Water</p>
            </div>
          <% end %>

          <div class="mb-4"></div>
          <div class="relative">
            <div class="absolute inset-px rounded-lg bg-white lg:rounded-l-[2rem]"></div>
            <div class="relative flex h-full flex-col overflow-hidden rounded-[calc(theme(borderRadius.lg)+1px)] lg:rounded-l-[calc(2rem+1px)]">
              <div class="px-8 pb-3 pt-8 sm:px-10 sm:pb-0 sm:pt-10">
                <%= for region <- @regions do %>
                  <.live_component
                    module={AlggroundWeb.Components.Region}
                    region={region}
                    id={region.region <> "#{System.unique_integer()}"}
                  />
                <% end %>
              </div>
            </div>
            <div class="pointer-events-none absolute inset-px rounded-lg shadow ring-1 ring-black/5 lg:rounded-l-[2rem]">
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp draw_groundwater(assigns, width) do
    graph = Contex.Sparkline.new(assigns.groundwater_levels)
    Contex.Sparkline.draw(%{graph | height: 100, width: width})
  end

  defp draw_rainfall(assigns, width) do
    graph = Contex.Sparkline.new(assigns.rainfall_levels)
    Contex.Sparkline.draw(%{graph | height: 100, width: width})
  end

  defp draw_reservoir(assigns, width) do
    graph = Contex.Sparkline.new(assigns.reservoir_levels)
    Contex.Sparkline.draw(%{graph | height: 100, width: width})
  end

  defp display_groundwater(assigns) do
    cond do
      assigns.groundwater >= 150 ->
        ~H"""
        <p class="mt-2 mx-auto flex justify-center text-lg/6 text-green-600 ">
          <%= @groundwater %> m
        </p>
        """

      assigns.groundwater < 150 and assigns.groundwater >= 50 ->
        ~H"""
        <p class="mt-2 mx-auto flex justify-center text-lg/6 text-amber-600 ">
          <%= @groundwater %> m
        </p>
        """

      assigns.groundwater < 50 ->
        ~H"""
        <p class="mt-2 mx-auto flex justify-center text-lg/6 text-red-600 ">
          <%= @groundwater %> m
        </p>
        """
    end
  end

  defp display_rainfall(assigns) do
    cond do
      assigns.rainfall >= 80 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-green-600 max-lg:text-center">
          <%= @rainfall %> ml
        </p>
        """

      assigns.rainfall < 80 and assigns.rainfall >= 30 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-amber-500 max-lg:text-center">
          <%= @rainfall %> ml
        </p>
        """

      assigns.rainfall < 30 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-red-600 max-lg:text-center">
          <%= @rainfall %> ml
        </p>
        """
    end
  end

  defp display_reservoirs(assigns) do
    cond do
      assigns.reservoir >= 6_000_000 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-green-600 max-lg:text-center">
          <%= @reservoir %> 10⁶km³
        </p>
        """

      assigns.reservoir < 6_000_000 and assigns.reservoir >= 1_200_000 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-amber-500 max-lg:text-center">
          <%= @reservoir %> 10⁶km³
        </p>
        """

      assigns.reservoir < 1_200_000 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-red-600 max-lg:text-center">
          <%= @reservoir %> 10⁶km³
        </p>
        """
    end
  end

  defp maybe_add_value(measurements) when length(measurements) > 15,
    do: Enum.drop(measurements, 1)

  defp maybe_add_value(measurements), do: measurements

  defp maybe_remove_value(measurements) when length(measurements) > 15 do
    measurements
    |> Enum.reverse()
    |> Enum.drop(1)
    |> Enum.reverse()
  end

  defp maybe_remove_value(measurements), do: measurements

  defp get_region(regions, region), do: List.first(Enum.filter(regions, &(&1.region == region)))
end
