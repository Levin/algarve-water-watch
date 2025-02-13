defmodule AlggroundWeb.LiveHomePage do
  use AlggroundWeb, :live_view

  alias Algground.DataManager

  def mount(_params, _session, socket) do
    municipalities = DataManager.get_municipalities()
    active_municipality = Enum.random(municipalities)
    
    # Convert Datex.Date to Elixir Date
    start_date = Date.utc_today()
    end_date = Date.add(Date.utc_today(), 90)
    
    # Load historical data for the graph
    historical_measurements = 
      -360..0  # Get last year of data in 90-day intervals
      |> Enum.take_every(90)
      |> Enum.map(fn days_offset ->
        date_start = Date.add(start_date, days_offset)
        date_end = Date.add(date_start, 90)
        DataManager.calculate_municipality_water_level(
          active_municipality.municipality,
          date_start,
          date_end
        )
      end)
      |> Enum.reject(&is_nil/1)  # Remove any nil measurements
      |> Enum.reverse()
    
    # Get water levels and percentiles for the active municipality
    water_levels = DataManager.calculate_municipality_water_level(
      active_municipality.municipality,
      start_date,
      end_date
    )
    
    percentiles = DataManager.calculate_percentiles(active_municipality.municipality)
    
    # Only add water_levels to measurements if it's not nil
    measurements = if water_levels, do: [water_levels | historical_measurements], else: historical_measurements
    
    active_municipality = 
      active_municipality
      |> Map.put(:groundwater_levels, water_levels)
      |> Map.put(:percentiles, percentiles)
      |> Map.put(:measurements, measurements)
    
    {:ok,
     socket
     |> assign(:groundwater_levels, Enum.map(municipalities, & &1.groundwater_levels))
     |> assign(:active_municipality, active_municipality)
     |> assign(:date_start, start_date)
     |> assign(:date_end, end_date)
     |> assign(:municipalities, municipalities)
     |> assign(:container_width, nil)
     |> assign(:live_action, :index)}
  end

  def handle_event("backward", _params, socket) do
    new_start_date = Date.add(socket.assigns.date_start, -90)
    new_end_date = Date.add(socket.assigns.date_end, -90)
    
    # Load historical data for the graph
    historical_measurements = 
      -360..0  # Get last year of data in 90-day intervals
      |> Enum.take_every(90)
      |> Enum.map(fn days_offset ->
        date_start = Date.add(new_start_date, days_offset)
        date_end = Date.add(date_start, 90)
        DataManager.calculate_municipality_water_level(
          socket.assigns.active_municipality.municipality,
          date_start,
          date_end
        )
      end)
      |> Enum.reject(&is_nil/1)  # Remove any nil measurements
      |> Enum.reverse()
    
    # Calculate new water levels for the active municipality
    water_levels = DataManager.calculate_municipality_water_level(
      socket.assigns.active_municipality.municipality,
      new_start_date,
      new_end_date
    )
    
    # Update active municipality with new water levels and measurements
    active_municipality = 
      socket.assigns.active_municipality
      |> Map.put(:groundwater_levels, water_levels)
      |> Map.put(:measurements, historical_measurements)

    {:noreply,
     socket
     |> assign(:date_start, new_start_date)
     |> assign(:date_end, new_end_date)
     |> assign(:active_municipality, active_municipality)}
  end

  def handle_event("forward", _params, socket) do
    if can_go_forward?(socket.assigns.date_end) do
      new_start_date = Date.add(socket.assigns.date_start, 90)
      new_end_date = Date.add(socket.assigns.date_end, 90)
      
      # Load historical data for the graph
      historical_measurements = 
        -360..0  # Get last year of data in 90-day intervals
        |> Enum.take_every(90)
        |> Enum.map(fn days_offset ->
          date_start = Date.add(new_start_date, days_offset)
          date_end = Date.add(date_start, 90)
          DataManager.calculate_municipality_water_level(
            socket.assigns.active_municipality.municipality,
            date_start,
            date_end
          )
        end)
        |> Enum.reject(&is_nil/1)  # Remove any nil measurements
        |> Enum.reverse()
      
      # Calculate new water levels for the active municipality
      water_levels = DataManager.calculate_municipality_water_level(
        socket.assigns.active_municipality.municipality,
        new_start_date,
        new_end_date
      )
      
      # Update active municipality with new water levels and measurements
      active_municipality = 
        socket.assigns.active_municipality
        |> Map.put(:groundwater_levels, water_levels)
        |> Map.put(:measurements, historical_measurements)

      {:noreply,
       socket
       |> assign(:date_start, new_start_date)
       |> assign(:date_end, new_end_date)
       |> assign(:active_municipality, active_municipality)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("select_municipality", %{"municipality" => municipality}, socket) do
    start_date = socket.assigns.date_start
    end_date = socket.assigns.date_end
    
    # Load historical data for the graph
    historical_measurements = 
      -360..0  # Get last year of data in 90-day intervals
      |> Enum.take_every(90)
      |> Enum.map(fn days_offset ->
        date_start = Date.add(start_date, days_offset)
        date_end = Date.add(date_start, 90)
        DataManager.calculate_municipality_water_level(
          municipality,
          date_start,
          date_end
        )
      end)
      |> Enum.reject(&is_nil/1)  # Remove any nil measurements
      |> Enum.reverse()
    
    # Get current water levels and percentiles
    water_levels = DataManager.calculate_municipality_water_level(
      municipality,
      start_date,
      end_date
    )
    
    percentiles = DataManager.calculate_percentiles(municipality)
    
    # Find the municipality in the list and update its water levels
    active_municipality = 
      get_municipality(socket.assigns.municipalities, municipality)
      |> Map.put(:groundwater_levels, water_levels)
      |> Map.put(:percentiles, percentiles)
      |> Map.put(:measurements, historical_measurements)
    
    {:noreply,
     socket
     |> assign(:active_municipality, active_municipality)}
  end


  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp can_go_forward?(date) do
    Date.compare(date, Date.utc_today()) == :lt
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="bg-gray-50 py-6 sm:py-6 rounded-lg">
        <div class="mx-auto max-w-2xl px-6 lg:max-w-7xl lg:px-8">
          <div class="flex justify-center mb-6">
            <.link
              navigate={~p"/feedback"}
              class="rounded-md bg-indigo-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            >
              Give Feedback
            </.link>
          </div>

          <div class="flex justify-evenly h-8">
            <svg 
              xmlns="http://www.w3.org/2000/svg" 
              viewBox="0 0 448 512" 
              phx-click="backward"
              class="cursor-pointer"
            >
              <path d="M9.4 233.4c-12.5 12.5-12.5 32.8 0 45.3l160 160c12.5 12.5 32.8 12.5 45.3 0s12.5-32.8 0-45.3L109.2 288 416 288c17.7 0 32-14.3 32-32s-14.3-32-32-32l-306.7 0L214.6 118.6c12.5-12.5 12.5-32.8 0-45.3s-32.8-12.5-45.3 0l-160 160z" />
            </svg>
            <p class="mx-auto max-w-lg text-pretty text-center font-medium tracking-tight text-gray-400 text-3xl">
              <%= Date.to_string(@date_start) %> to <%= Date.to_string(@date_end) %>
            </p>

            <svg 
              xmlns="http://www.w3.org/2000/svg" 
              viewBox="0 0 448 512" 
              phx-click={if can_go_forward?(@date_end), do: "forward"}
              class={"cursor-pointer #{if !can_go_forward?(@date_end), do: "opacity-50"}"}
            >
              <path d="M438.6 278.6c12.5-12.5 12.5-32.8 0-45.3l-160-160c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3L338.8 224 32 224c-17.7 0-32 14.3-32 32s14.3 32 32 32l306.7 0L233.4 393.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0l160-160z" />
            </svg>
          </div>
          <p class="mx-auto max-w-lg text-pretty text-center font-medium tracking-tight text-gray-950 text-3xl lg:mt-4 mt-10">
            in <%= @active_municipality.municipality %>
          </p>
          <%= display_groundwater(assigns) %>
          <%= if @active_municipality.measurements && length(@active_municipality.measurements) > 1 do %>
            <div class="mt-4 px-10">
              <%= draw_groundwater(%{groundwater_levels: @active_municipality.measurements}, 700) %>
            </div>
          <% end %>
          <div class="flex justify-left ">
            <p class="flex gap-2 mx-auto text-pretty font-sm tracking-tight text-gray-400 text-sm cursor-pointer">
              Ground Water Level
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 320 512"
                class="h-6 w-6 left-2.5 top-2 border rounded-full bg-gray-200 p-1"
                phx-click={show_modal("groundwater-info")}
              >
                <path d="M80 160c0-35.3 28.7-64 64-64l32 0c35.3 0 64 28.7 64 64l0 3.6c0 21.8-11.1 42.1-29.4 53.8l-42.2 27.1c-25.2 16.2-40.4 44.1-40.4 74l0 1.4c0 17.7 14.3 32 32 32s32-14.3 32-32l0-1.4c0-8.2 4.2-15.8 11-20.2l42.2-27.1c36.6-23.6 58.8-64.1 58.8-107.7l0-3.6c0-70.7-57.3-128-128-128l-32 0C73.3 32 16 89.3 16 160c0 17.7 14.3 32 32 32s32-14.3 32-32zm80 320a40 40 0 1 0 0-80 40 40 0 1 0 0 80z" />
              </svg>
            </p>
          </div>

          <.modal id="groundwater-info">
            <div class="mt-2 text-sm leading-6 text-zinc-600">
              <h3 class="text-lg font-semibold mb-2">Understanding Groundwater in the Algarve</h3>
              
              <h4 class="font-semibold mt-4 mb-1">Why Groundwater Matters</h4>
              <p class="mb-2">Groundwater is crucial for the Algarve region for several reasons:</p>
              <ul class="list-disc pl-5 space-y-1 mb-4">
                <li>It's a vital water source during dry seasons and droughts</li>
                <li>Supports agriculture and tourism, the region's main economic activities</li>
                <li>Helps maintain natural ecosystems and prevents saltwater intrusion</li>
                <li>Acts as a buffer during periods of low rainfall</li>
              </ul>

              <h4 class="font-semibold mt-4 mb-1">Our Data</h4>
              <p class="mb-2">We collect data from the Portuguese Water Resources Information System (SNIRH):</p>
              <ul class="list-disc pl-5 space-y-1 mb-4">
                <li>Historical data spanning multiple decades</li>
                <li>Coverage of all major aquifers in the region</li>
              </ul>

              <h4 class="font-semibold mt-4 mb-1">Understanding the Measurements</h4>
              <ul class="list-disc pl-5 space-y-1">
                <li>Values show the depth of water below ground level</li>
                <li>Lower numbers mean higher water levels (better)</li>
                <li>We compare current levels with historical data to assess the situation</li>
                <li>Data is averaged over 90-day periods to show clear trends</li>
              </ul>
            </div>
          </.modal>

          <div class="mt-10 grid gap-4 sm:mt-4 lg:rounded-t-[2rem]">
            <div class="relative mb-4">
              <div class="relative flex h-full flex-col overflow-hidden rounded-[calc(2rem+1px)]">
                <.modal :if={@live_action == :show_groundwater_info} id="groundwater_info" show on_cancel={JS.patch(~p"/")}>
                  <div class="mt-2 text-sm leading-6 text-zinc-600">
                    <h3 class="text-lg font-semibold mb-2">Understanding the Water Level Graph</h3>
                    <p class="mb-2">The graph shows historical groundwater levels over time:</p>
                    <ul class="list-disc pl-5 space-y-1">
                      <li>Each point represents the average water level over a 90-day period</li>
                      <li>The graph shows up to one year of historical data</li>
                      <li>Higher values indicate higher water levels (better)</li>
                      <li>The color coding indicates the current level relative to historical data:
                        <ul class="list-disc pl-5 mt-1">
                          <li>Green: Above 70th percentile (good)</li>
                          <li>Orange: Between 30th and 70th percentile (moderate)</li>
                          <li>Red: Below 30th percentile (concerning)</li>
                        </ul>
                      </li>
                    </ul>
                  </div>
                </.modal>
              </div>
              <div class="pointer-events-none absolute inset-px rounded-lg shadow ring-1 ring-black/5 max-lg:rounded-t-[2rem]">
              </div>
            </div>
          </div>

            <div class="rounded-sm bg-white lg:rounded-t-[2rem] px-8 pt-4 contain block md:hidden">
              <%= draw_groundwater(%{groundwater_levels: @active_municipality.measurements}, 280) %>
            </div>

          <div class="flex justify-center px-4">
            <p class="text-md font-medium tracking-tight text-gray-400 max-lg:text-center">
              Ground Water Level
            </p>
          </div>

          <div class="mb-4"></div>
          <div class="relative">
            <div class="absolute inset-px rounded-lg bg-white lg:rounded-l-[2rem]"></div>
            <div class="relative flex h-full flex-col overflow-hidden rounded-[calc(theme(borderRadius.lg)+1px)] lg:rounded-l-[calc(2rem+1px)]">
              <div class="px-8 pb-3 pt-8 sm:px-10 sm:pb-0 sm:pt-10">
                <%= for municipality <- @municipalities do %>
                    <.live_component
                      module={AlggroundWeb.Components.Region}
                      region={municipality}
                      id={municipality.municipality <> "#{System.unique_integer()}"}
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

  defp draw_groundwater(%{groundwater_levels: levels}, width) when is_list(levels) and length(levels) > 0 do
    graph = Contex.Sparkline.new(levels)
    Contex.Sparkline.draw(%{graph | height: 100, width: width})
  end

  defp draw_groundwater(_assigns, _width) do
    assigns = %{inner_content: "No historical data available"}
    ~H"""
    <div class="flex justify-center items-center h-[100px] text-gray-500">
      <%= @inner_content %>
    </div>
    """
  end


  defp display_groundwater(assigns) do
    case assigns.active_municipality do
      %{groundwater_levels: nil} -> 
        ~H"""
        <p class="mt-2 mx-auto flex justify-center text-lg/6 text-gray-600">
          No data available
        </p>
        """
      %{groundwater_levels: levels, percentiles: %{p30: p30, p70: p70}} when is_number(levels) -> 
        assigns = 
          assign(assigns, :color_class, 
            cond do
              levels >= p70 -> "text-green-600"
              levels >= p30 -> "text-amber-600"
              true -> "text-red-600"
            end)
          |> assign(:formatted_level, 
            levels
            |> Kernel./(1)
            |> Float.round(2)
            |> Float.to_string())
        
        ~H"""
        <p class={"mt-2 mx-auto flex justify-center text-lg/6 #{@color_class}"}>
          <%= @formatted_level %> meters below ground
        </p>
        """
      _ -> 
        ~H"""
        <p class="mt-2 mx-auto flex justify-center text-lg/6 text-gray-600">
          No data available
        </p>
        """
    end
  end

  defp get_municipality(municipalitys, municipality), do: List.first(Enum.filter(municipalitys, &(&1.municipality == municipality)))

end
