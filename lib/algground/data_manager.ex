defmodule Algground.DataManager do
  use GenServer
  require Logger
  alias NimbleCSV.RFC4180, as: CSV

  @data_folder "data/"
  @stations_file "algarve_stations.csv"
  @capture_points_folder "capture_points/"

  # Public function to get the municipality map
  def get_municipality_map do
    GenServer.call(__MODULE__, :get_municipality_map)
  end

  # Public function to get the municipality names that we have from the csv
  def get_municipalities() do
    GenServer.call(__MODULE__, :get_municipality_skeletons)
  end

  # Get biweekly water levels for a municipality
  def get_biweekly_water_levels(municipality, num_periods \\ 12) do
    GenServer.call(__MODULE__, {:get_biweekly_levels, municipality, num_periods})
  end

  def calculate_municipality_water_level(municipality, start_date, end_date) do
    GenServer.call(__MODULE__, {:calculate_water_levels, municipality, start_date, end_date})
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_opts) do
    Logger.info(".... [#{__MODULE__}] started and collects data now ....")
    {:ok, %{}, {:continue, :gather_data}}
  end

  def handle_continue(:gather_data, state) do
    municipality_map = create_municipality_map()
    Logger.info("Created municipality map with #{map_size(municipality_map)} municipalities")

    {:noreply, Map.put(state, :municipality_map, municipality_map)}
  end

  def handle_call(:get_municipality_skeletons, _from, %{municipality_map: municipality_map} = state) do
    municipalities = 
      municipality_map
      |> Map.keys()
      |> Enum.map(&%{region: String.capitalize(&1)})
    
    {:reply, municipalities, state}
  end

  def handle_call(:get_municipality_map, _from, state) do
    {:reply, Map.get(state, :municipality_map, %{}), state}
  end

  def handle_call({:get_biweekly_levels, municipality, num_periods}, _from, state) do
    municipalities = Map.get(state, :municipality_map, %{})
    
    case Map.get(municipalities, municipality) do
      %{capture_points: capture_points} ->
        # Calculate start date as num_periods * 2 weeks ago
        end_date = Date.utc_today()
        start_date = Date.add(end_date, -num_periods * 14)
        
        # Generate list of biweekly periods
        periods = generate_biweekly_periods(start_date, end_date)
        
        # Calculate water levels for each period
        levels = calculate_period_levels(capture_points, periods)
        
        {:reply, levels, state}
      _ ->
        {:reply, [], state}
    end
  end

  def handle_call({:calculate_water_levels, municipality, start_date, end_date}, _from, state) do
    municipalities = Map.get(state, :municipality_map, %{})
    water_levels = 
      case Map.get(municipalities, municipality, %{}) do
        %{
          municipality: municipality,
          capture_points: capture_points
        } ->
          capture_points
          |> MapSet.to_list()
          |> Enum.map(fn point_id ->
            # 1. Read through the files in capture points
            file_path = Path.join([@data_folder, @capture_points_folder, "#{point_id}.csv"])

            case File.exists?(file_path) do
              true ->
                file_path
                |> File.stream!()
                |> CSV.parse_stream()
                |> Stream.drop(1)  # Skip header
                |> Stream.map(fn [date_str, level_str] ->
                  # Convert date string to Date
                  with {:ok, date} <- Date.from_iso8601(date_str),
                    {level, _} <- Float.parse(level_str) do
                    {date, level}
                  else
                    _ -> nil
                  end
                end)
                |> Stream.reject(&is_nil/1)
                # 2. Find datapoints between start and end date
                |> Stream.filter(fn {date, _level} ->
                  Date.compare(date, start_date) in [:gt, :eq] and
                    Date.compare(date, end_date) in [:lt, :eq]
                end)
                # 3. Extract measurement values only
                |> Enum.map(fn {_date, level} -> level end)
                |> case do
                  [] -> nil
                  levels -> Enum.sum(levels) / length(levels)  # Calculate average
                end
              false -> 
                nil
            end
          end)
          |> Enum.reject(&is_nil/1)
          |> case do
            [] -> 0  # Return 0 if no valid measurements found
            measurements -> Enum.sum(measurements) / length(measurements)  # Average across all stations
          end
        %{} -> 0
      end

    {:reply, water_levels, state}
  end

  # Generate list of start and end dates for biweekly periods
  defp generate_biweekly_periods(start_date, end_date) do
    Stream.unfold(start_date, fn current_start ->
      if Date.compare(current_start, end_date) == :gt do
        nil
      else
        period_end = Date.add(current_start, 13) # 14 days - 1
        {
          {current_start, period_end},
          Date.add(current_start, 14)
        }
      end
    end)
    |> Enum.to_list()
  end

  # Calculate water levels for each period
  defp calculate_period_levels(capture_points, periods) do
    periods
    |> Enum.map(fn {period_start, period_end} ->
      capture_points
      |> MapSet.to_list()
      |> Enum.map(fn point_id ->
        file_path = Path.join([@data_folder, @capture_points_folder, "#{point_id}.csv"])

        case File.exists?(file_path) do
          true ->
            file_path
            |> File.stream!()
            |> CSV.parse_stream()
            |> Stream.drop(1)
            |> Stream.map(fn [date_str, level_str] ->
              with {:ok, date} <- Date.from_iso8601(date_str),
                   {level, _} <- Float.parse(level_str) do
                {date, level}
              else
                _ -> nil
              end
            end)
            |> Stream.reject(&is_nil/1)
            |> Stream.filter(fn {date, _level} ->
              Date.compare(date, period_start) in [:gt, :eq] and
                Date.compare(date, period_end) in [:lt, :eq]
            end)
            |> Enum.map(fn {_date, level} -> level end)
            |> case do
              [] -> nil
              levels -> Enum.sum(levels) / length(levels)
            end
          false -> 
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> case do
        [] -> 0
        measurements -> Enum.sum(measurements) / length(measurements)
      end
    end)
  end

  # Creates a map of municipalities and their capture point IDs
  defp create_municipality_map do
    stations_path = Path.join(@data_folder, @stations_file)

    stations_path
    |> File.stream!()
    |> CSV.parse_stream()
    |> Stream.drop(1)
    |> Enum.reduce(%{}, fn row, acc ->
      [
        _id,
        _name,
        _district,
        municipality,
        _freguesia,
        _bacia,
        _altitude,
        _coord_x,
        _coord_y,
        _sistema_aquifero,
        _estado,
        marker_site,
        _latitude,
        _longitude,
        _site_id
      ] = row

      case municipality do
        "" ->
          acc

        municipality ->
          Map.update(
            acc,
            municipality,
            %{
              municipality: municipality,
              capture_points: MapSet.new([marker_site])
            },
            fn existing ->
              %{existing | capture_points: MapSet.put(existing.capture_points, marker_site)}
            end
          )
      end
    end)
  end
end
