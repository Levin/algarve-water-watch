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

  def calculate_municipality_water_level(municipality, start_date, end_date) do
    dbg()
    GenServer.call(__MODULE__, {:calculate_water_levels, municipality, start_date, end_date})
  end

  def calculate_percentiles(municipality) do
    GenServer.call(__MODULE__, {:calculate_percentiles, municipality})
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
      |> Enum.map(fn municipality -> %{municipality: String.capitalize(municipality), groundwater_levels: nil} end)
    {:reply, municipalities, state}
  end

  def handle_call(:get_municipality_map, _from, state) do
    {:reply, Map.get(state, :municipality_map, %{}), state}
  end

  def handle_call({:calculate_water_levels, municipality, start_date, end_date}, _from, state) do
    municipalities = Map.get(state, :municipality_map, %{})
    water_levels = 
      case Map.get(municipalities, String.upcase(municipality)) do
        %{
          municipality: municipality,
          capture_points: capture_points
        } ->
          capture_points
          |> MapSet.to_list()
          |> Enum.map(fn point_id ->
            read_water_levels(point_id, start_date, end_date)
          end)
          |> Enum.reject(&is_nil/1)
          |> case do
            [] -> 0
            measurements -> Enum.sum(measurements) / length(measurements)
          end
        %{} -> 0
      end

    {:reply, water_levels, state}
  end

  def handle_call({:calculate_percentiles, municipality}, _from, state) do
    municipalities = Map.get(state, :municipality_map, %{})
    capture_points = 
      case Map.get(municipalities, String.upcase(municipality)) do
        %{capture_points: capture_points} -> capture_points
        %{} -> MapSet.new()
      end

    all_levels = 
      capture_points
      |> MapSet.to_list()
      |> Enum.flat_map(fn point_id ->
        csv_path = Path.join([@data_folder, @capture_points_folder, "#{point_id}.csv"])
        
        if File.exists?(csv_path) do
          csv_path
          |> File.stream!()
          |> CSV.parse_stream()
          |> Stream.drop(1)  # Skip header
          |> Stream.map(fn [_date, level] -> 
            case Float.parse(level) do
              {value, _} -> value
              :error -> nil
            end
          end)
          |> Stream.filter(&(&1 != nil))  # Remove nil values
          |> Enum.to_list()
        else
          []
        end
      end)
      |> Enum.sort()

    case all_levels do
      [] -> 
        {:reply, %{p30: 0.0, p70: 0.0}, state}  # Default if no data
      levels -> 
        len = length(levels)
        p30_index = floor(len * 0.3)
        p70_index = floor(len * 0.7)
        
        {:reply, %{
          p30: Enum.at(levels, p30_index),
          p70: Enum.at(levels, p70_index)
        }, state}
    end
  end

  # Shared function to read and process water levels from a CSV file
  defp read_water_levels(point_id, start_date, end_date) do
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
        |> Stream.filter(fn {date, _level} ->
          Date.compare(date, start_date) in [:gt, :eq] and
            Date.compare(date, end_date) in [:lt, :eq]
        end)
        |> Enum.map(fn {_date, level} -> level end)
        |> case do
          [] -> nil
          levels -> Enum.sum(levels) / length(levels)
        end
      false -> 
        nil
    end
  end

  # Creates a map of municipalities and their capture point IDs
  defp create_municipality_map do
    stations_path = Path.join(@data_folder, @stations_file)

    stations_path
    |> File.stream!()
    |> CSV.parse_stream()
    # Skip header row
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

      # Skip empty municipalities
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
