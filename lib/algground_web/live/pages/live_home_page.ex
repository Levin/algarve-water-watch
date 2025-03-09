defmodule AlggroundWeb.LiveHomePage do
  use AlggroundWeb, :live_view

  alias Algground.DataManager
  require Tucan

  @doc """
    Mount the live view that shows users the current water level of a region.

    This view displays:
    1. The current water level of a randomly selected municipality (in cm)
    2. A histogram of historical water levels for the last 5 years using the Tucan library

    The histogram displays water level data grouped by quarters (Q1, Q2, Q3, Q4) for each year,
    showing the data sequentially quarter by quarter, not sorted from highest to lowest.
    This chronological presentation allows users to observe seasonal patterns and long-term trends
    in groundwater levels over the 5-year period.

    User interaction:
    - When a user clicks on a location in the list, they are automatically scrolled back to the top
      of the page to see the newly loaded graph and water level information for that location. we use an id for that and send the user to the id of a div at the top of the page.

    in order for users to see the graph from the beginning on completely, the graph should have a reasonable size. users (except on phones) should not need to scroll and to see the complete informtaion of the graph.


    For more information on the Tucan library, see: https://github.com/pnezis/tucan
  """

  def mount(_params, _session, socket) do
    municipalities = DataManager.get_municipalities()
    active_municipality = Enum.random(municipalities)
    map_file = Path.join([Application.app_dir(:algground), "priv/data/us-10m.json"])
    data_file = Path.join([Application.app_dir(:algground), "priv/data/unemployment.tsv"])
    IO.inspect(map_file)

    # Start from the last complete month
    today = Date.utc_today()
    end_date = Date.end_of_month(Date.add(today, -31))  # Get end of previous month
    start_date = Date.beginning_of_month(end_date)  # Get start of that month

    # Load historical data for the graph - last 5 years (60 months)
    historical_measurements =
      0..59  # Last 60 months (5 years)
      |> Enum.map(fn month_offset ->
        month_end_date = Date.end_of_month(Date.add(end_date, -month_offset * 31))
        month_start_date = Date.beginning_of_month(month_end_date)
        level = DataManager.calculate_municipality_water_level(
          active_municipality.municipality,
          month_start_date,
          month_end_date
        )
        {month_end_date, level}  # Store the date with the measurement
      end)
      |> Enum.reject(fn {_date, level} -> is_nil(level) end)  # Remove any nil measurements

    # Get water levels and percentiles for the active municipality
    water_levels = DataManager.calculate_municipality_water_level(
      active_municipality.municipality,
      start_date,
      end_date
    )

    percentiles = DataManager.calculate_percentiles(active_municipality.municipality)

    # Only add water_levels to measurements if it's not nil
    measurements =
      if water_levels do
        [{end_date, water_levels} | historical_measurements]
      else
        historical_measurements
      end

    active_municipality =
      active_municipality
      |> Map.put(:groundwater_levels, water_levels)
      |> Map.put(:percentiles, percentiles)
      |> Map.put(:measurements, measurements)


    ## load the Algarve map

    {:ok,
     socket
     |> assign(:groundwater_levels, Enum.map(municipalities, & &1.groundwater_levels))
     |> assign(:active_municipality, active_municipality)
     |> assign(:date_start, start_date)
     |> assign(:date_end, end_date)
     |> assign(:municipalities, municipalities)
     |> assign(:container_width, 800)  # Default width, will be updated by JS hook
     |> assign(:live_action, :index)
     |> assign(:map_file, map_file)
     |> assign(:data_file, data_file)
    }
  end

  def handle_event("backward", _params, socket) do
    # Move back one month
    current_start = socket.assigns.date_start
    new_start_date = Date.beginning_of_month(Date.add(current_start, -1))  # Go to start of previous month
    new_end_date = Date.end_of_month(new_start_date)  # Go to end of that month

    # Load historical data for the graph - last 5 years (60 months)
    historical_measurements =
      0..59  # Last 60 months (5 years)
      |> Enum.map(fn month_offset ->
        month_end_date = Date.end_of_month(Date.add(new_end_date, -month_offset * 31))
        month_start_date = Date.beginning_of_month(month_end_date)
        level = DataManager.calculate_municipality_water_level(
          socket.assigns.active_municipality.municipality,
          month_start_date,
          month_end_date
        )
        {month_end_date, level}  # Store the date with the measurement
      end)
      |> Enum.reject(fn {_date, level} -> is_nil(level) end)

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
      # Move forward one month
      current_start = socket.assigns.date_start
      new_start_date = Date.beginning_of_month(Date.add(current_start, 31))  # Go to start of next month
      new_end_date = Date.end_of_month(new_start_date)  # Go to end of that month

      # Make sure we don't go past the last complete month
      last_complete_month = Date.end_of_month(Date.add(Date.utc_today(), -31))
      {new_start_date, new_end_date} =
        if Date.compare(new_end_date, last_complete_month) == :gt do
          {Date.beginning_of_month(last_complete_month), last_complete_month}
        else
          {new_start_date, new_end_date}
        end

      # Load historical data for the graph - last 5 years (60 months)
      historical_measurements =
        0..59  # Last 60 months (5 years)
        |> Enum.map(fn month_offset ->
          month_end_date = Date.end_of_month(Date.add(new_end_date, -month_offset * 31))
          month_start_date = Date.beginning_of_month(month_end_date)
          level = DataManager.calculate_municipality_water_level(
            socket.assigns.active_municipality.municipality,
            month_start_date,
            month_end_date
          )
          {month_end_date, level}  # Store the date with the measurement
        end)
        |> Enum.reject(fn {_date, level} -> is_nil(level) end)

      # Calculate new water levels for the active municipality
      water_levels = DataManager.calculate_municipality_water_level(
        socket.assigns.active_municipality.municipality,
        new_start_date,
        new_end_date
      )

      # Only add water_levels to measurements if it's not nil
      measurements =
        if water_levels do
          [{new_end_date, water_levels} | historical_measurements]
        else
          historical_measurements
        end

      active_municipality =
        socket.assigns.active_municipality
        |> Map.put(:groundwater_levels, water_levels)
        |> Map.put(:measurements, measurements)

      {:noreply,
       socket
       |> assign(:date_start, new_start_date)
       |> assign(:date_end, new_end_date)
       |> assign(:active_municipality, active_municipality)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_container_width", %{"width" => width}, socket) do
    # Update the container width in the socket assigns
    {:noreply, assign(socket, :container_width, width)}
  end

  def handle_event("select_municipality", %{"municipality" => municipality}, socket) do
    start_date = socket.assigns.date_start
    end_date = socket.assigns.date_end

    # Load historical data for the graph
    historical_measurements =
      0..59  # Last 60 months (5 years)
      |> Enum.map(fn month_offset ->
        month_end_date = Date.end_of_month(Date.add(end_date, -month_offset * 31))
        month_start_date = Date.beginning_of_month(month_end_date)
        level = DataManager.calculate_municipality_water_level(
          municipality,
          month_start_date,
          month_end_date
        )
        {month_end_date, level}  # Store the date with the measurement
      end)
      |> Enum.reject(fn {_date, level} -> is_nil(level) end)  # Remove any nil measurements

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

    # Send a push event to scroll to the top of the page
    socket =
      socket
      |> assign(:active_municipality, active_municipality)
      |> push_event("scroll_to_top", %{id: "top-graph-section"})

    {:noreply, socket}
  end


  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp can_go_forward?(current_end_date) do
    # Can go forward if we're not at the last complete month
    last_complete_month = Date.end_of_month(Date.add(Date.utc_today(), -31))
    Date.compare(current_end_date, last_complete_month) == :lt
  end

  def render(assigns) do
    ~H"""
    <div id="main-view" phx-hook="ScrollHandler">
      <div class="bg-gray-50 py-6 sm:py-6 rounded-lg">
        <div class="mx-auto max-w-3xl px-6 lg:max-w-7xl lg:px-8">
          <div class="flex justify-center mb-6">
            <.link
              navigate={~p"/feedback"}
              class="rounded-md bg-indigo-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            >
              Give Feedback
            </.link>
          </div>

          <div id="top-graph-section" class="flex justify-evenly h-8">
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
            <div class="mt-6 mb-8 px-2 w-full">
              <div id="chart-container" phx-hook="ContainerWidth" class="bg-white p-4 rounded-lg shadow-sm min-h-[350px] overflow-hidden">
                <%= draw_groundwater(@active_municipality, @container_width) %>
              </div>
            </div>
          <% end %>
          <div class="flex justify-center px-4 mt-2">
            <p class="text-md font-medium tracking-tight text-gray-400 max-lg:text-center">
              Ground Water Level MAP
            </p>
          </div>
          <%!-- map --%>
          <div id="chart-container" phx-hook="ContainerWidth" class="bg-white p-4 rounded-lg shadow-sm min-h-[350px] overflow-hidden">
          <%= render_map(assigns) %>
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
          <div class="mt-10 grid gap-4 sm:mt-4 lg:rounded-t-[2rem]">
            <div class="relative mb-4">
              <div class="relative flex h-full flex-col overflow-hidden rounded-[calc(2rem+1px)]">
                <.modal :if={@live_action == :show_groundwater_info} id="groundwater_info" show on_cancel={JS.patch(~p"/")}>
                  <div class="mt-2 text-sm leading-6 text-zinc-600">
                    <h3 class="text-lg font-semibold mb-2">Understanding the Water Level Graph</h3>
                    <p class="mb-2">The graph shows historical groundwater levels over time:</p>
                    <ul class="list-disc pl-5 space-y-1">
                      <li>Each point represents the average water level over a month</li>
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
              <%= draw_groundwater(@active_municipality, @container_width) %>
            </div>
        </div>
      </div>
    </div>
    """
  end

  defp draw_groundwater(%{measurements: measurements} = municipality, width) when is_list(measurements) and length(measurements) > 0 do
    # Filter out 0.0 values (insufficient data)
    valid_measurements = Enum.reject(measurements, fn {_date, level} -> level == 0.0 end)

    case valid_measurements do
      [] ->
        assigns = %{message: "No historical data available"}
        ~H"""
        <div class="flex justify-center items-center h-[100px] text-gray-500">
          <%= @message %>
        </div>
        """

      measurements ->
        # Extract data for histogram
        _levels = Enum.map(measurements, fn {_date, level} -> level end)

        # Group data by year and month for better visualization
        grouped_data =
          measurements
          |> Enum.group_by(
            fn {date, _level} ->
              year = date.year
              # Group into quarters
              quarter = div(date.month - 1, 3) + 1
              "#{year}-Q#{quarter}"
            end,
            fn {_date, level} -> level end
          )
          |> Enum.map(fn {period, values} ->
            # Calculate average for the period
            avg = Enum.sum(values) / length(values)
            %{period: period, level: avg}
          end)
          |> Enum.sort_by(fn %{period: period} -> period end)  # Sort chronologically
          |> Enum.take(20) # Show last 20 quarters (5 years)

        # Get percentiles for reference lines
        percentiles = Map.get(municipality, :percentiles, %{p30: 0, p70: 0})

        # Helper function to format the quarter for better display
        format_quarter = fn period ->
          [year, quarter] = String.split(period, "-")
          "#{quarter} #{year}"
        end

        chart_data = Enum.map(grouped_data, fn %{period: period, level: level} ->
          %{period: format_quarter.(period), level: level}
        end)

        # Calculate appropriate width based on container or default to provided width
        # effective_width = width || 800

        spec = %{
          "$schema" => "https://vega.github.io/schema/vega-lite/v5.json",
          "description" => "Groundwater Levels - Last 5 Years (Quarterly Average)",
          "width" => "container",  # Use container width for responsiveness
          "height" => 300,
          "autosize" => %{
            "type" => "fit",
            "contains" => "padding"
          },
          "padding" => %{
            "top" => 20,
            "right" => 20,
            "bottom" => 40,
            "left" => 60
          },
          "title" => %{
            "text" => "Groundwater Levels - Last 5 Years (Quarterly Average)",
            "fontSize" => 14
          },
          "data" => %{"values" => chart_data},
          "mark" => %{
            "type" => "bar",
            "tooltip" => true,
            "cornerRadius" => 2,
            "color" => "#4F46E5"
          },
          "encoding" => %{
            "x" => %{
              "field" => "period",
              "type" => "nominal",
              "title" => "Period",
              "sort" => nil,  # Use the data order as provided (chronological)
              "axis" => %{
                "labelAngle" => -45,
                "labelFontSize" => 11,
                "labelLimit" => 100,
                "labelOverlap" => "parity"
              }
            },
            "y" => %{
              "field" => "level",
              "type" => "quantitative",
              "title" => "Centimeters Above Sea Level",
            }
          },
          "config" => %{
            "view" => %{"stroke" => "transparent"},
            "axis" => %{"domainWidth" => 1}
          }
        }

        # Add reference lines if available
        spec = if percentiles.p30 > 0 and percentiles.p70 > 0 do
          # This is a simplified version without reference lines
          spec
        else
          spec
        end

        assigns = %{chart: spec}
        ~H"""
        <div id="histogram" phx-hook="VegaLite" data-spec={Jason.encode!(@chart)} class="w-full h-[300px] flex justify-center items-center">
        </div>
        """
    end
  end

  defp draw_groundwater(_municipality, _width) do
    assigns = %{message: "No historical data available"}

    ~H"""
    <div class="flex justify-center items-center h-[100px] text-gray-500">
      <%= @message %>
    </div>
    """
  end

  defp display_groundwater(assigns) do
    case assigns.active_municipality do
      %{groundwater_levels: levels} when not is_nil(levels) ->
        assigns =
          assigns
          |> assign(:color_class, case levels do
            0.0 -> "text-gray-600"
            level when level > assigns.active_municipality.percentiles.p70 -> "text-green-600"
            level when level < assigns.active_municipality.percentiles.p30 -> "text-red-600"
            _ -> "text-orange-600"
          end)
          |> assign(:formatted_level, case levels do
            0.0 -> "Insufficient data"
            level -> "#{Float.round(level * 100, 2)} centimeters below ground"
          end)

        ~H"""
        <p class={"mt-2 mx-auto flex justify-center text-lg/6 #{@color_class}"}>
          <%= @formatted_level %>
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

  defp render_map(assigns) do
    IO.inspect(assigns.map_file)
    spec = %{
      "$schema" => "https://vega.github.io/schema/vega-lite/v5.json",
      "description" => "Groundwater Levels - Last 5 Years (Quarterly Average)",
      "width" => "container",  # Use container width for responsiveness
      "height" => 300,
      "autosize" => %{
        "type" => "fit",
        "contains" => "padding"
      },
      "padding" => %{
        "top" => 20,
        "right" => 20,
        "bottom" => 40,
        "left" => 60
      },
      "title" => %{
        "text" => "Portugal's Districts",
        "fontSize" => 14
      },
      "data" => %{
        # "url" =>"https://raw.githubusercontent.com/vega/vega/refs/heads/main/docs/data/us-10m.json",
        # "url" => "https://raw.githubusercontent.com/leakyMirror/map-of-europe/27a335110674ae5b01a84d3501b227e661beea2b/TopoJSON/europe.topojson",
        "url" => "https://raw.githubusercontent.com/stcoimbra/PowerBI-TopoJson-Portugal/refs/heads/main/concelhos_portugal%20(1).json",
        "format" => %{
          "type" => "topojson",
          "feature" => "concelhos_portugal"
        }
      },
      "transform" => [%{
        "lookup" => "id",
        "from"=> %{
          "data" => %{
            "url"=> "https://raw.githubusercontent.com/vega/vega/refs/heads/main/docs/data/unemployment.tsv",
          },
          "key" => "id",
          "fields" => ["rate"]
        }
      }],
      "projection" => %{
        "type" => "albersUsa"
      },
      "mark" => "geoshape",
      "encoding" => %{
        "color"=> %{
          "field" => "rate",
          "type" => "quantitative"
        }
      }
    }

    assigns = %{gis: spec}
    ~H"""
    <div id="gis-container" phx-hook="VegaLite" data-spec={Jason.encode!(@gis)} class="w-full h-[300px] flex justify-center items-center">
    </div>
    """
  end
end
