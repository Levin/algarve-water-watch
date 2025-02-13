defmodule Algground.DataManager do
  use GenServer
  require Logger
  alias NimbleCSV.RFC4180, as: CSV

  @data_folder "data"
  @stations_file "algarve_stations.csv"
  @capture_points_folder "capture_points"

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
        nil -> 
          0.0
        capture_points -> 
          # Get measurements from all capture points
          all_measurements = 
            capture_points
            |> MapSet.to_list()
            |> Enum.flat_map(fn point_id ->
              read_water_levels(point_id, start_date, end_date)
            end)

          # Average all measurements for each date
          case all_measurements do
            [] -> 
              0.0
            measurements ->
              measurements
              |> Enum.map(fn {_date, level} -> level end)
              |> then(fn levels -> Enum.sum(levels) / length(levels) end)
          end
      end

    {:reply, water_levels, state}
  end

  def handle_call({:calculate_percentiles, municipality}, _from, state) do
    municipalities = Map.get(state, :municipality_map, %{})
    capture_points = Map.get(municipalities, String.upcase(municipality), MapSet.new())

    result = 
      capture_points
      |> MapSet.to_list()
      |> Enum.flat_map(fn point_id ->
        get_all_water_levels(point_id)
      end)
      |> case do
        [] -> 
          %{p30: 0.0, p70: 0.0}
        levels -> 
          sorted = Enum.sort(levels)
          count = length(sorted)
          p30_index = floor(count * 0.3)
          p70_index = floor(count * 0.7)
          
          %{
            p30: Enum.at(sorted, p30_index, 0.0),
            p70: Enum.at(sorted, p70_index, 0.0)
          }
      end

    {:reply, result, state}
  end

  # Shared function to read and process water levels from a CSV file
  defp read_water_levels(point_id, start_date, end_date) do
    file_path = get_file_path(Path.join(@capture_points_folder, "#{point_id}.csv"))

    case File.exists?(file_path) do
      true ->
        file_path
        |> File.stream!()
        |> CSV.parse_stream()
        |> Stream.drop(1)  # Skip header row
        |> Stream.map(fn [date, level] ->
          with {:ok, parsed_date} <- Date.from_iso8601(date),
               {parsed_level, _} <- Float.parse(level) do
            {parsed_date, parsed_level}
          else
            _ -> nil
          end
        end)
        |> Stream.reject(&is_nil/1)
        |> Stream.filter(fn {date, _level} ->
          Date.compare(date, start_date) != :lt && Date.compare(date, end_date) != :gt
        end)
        |> Enum.to_list()

      false ->
        []
    end
  end

  defp get_all_water_levels(point_id) do
    file_path = get_file_path(Path.join(@capture_points_folder, "#{point_id}.csv"))

    if File.exists?(file_path) do
      file_path
      |> File.stream!()
      |> CSV.parse_stream()
      |> Stream.drop(1)  # Skip header row
      |> Stream.map(fn [_date, level] -> 
        case Float.parse(level) do
          {value, _} -> value
          _ -> nil
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.to_list()
    else
      []
    end
  end

  defp get_file_path(file) do
    :algground
    |> Application.app_dir("priv")
    |> Path.join(@data_folder)
    |> Path.join(file)
  end

  # Creates a map of municipalities and their capture point IDs
  defp create_municipality_map do
    stations_path = get_file_path(@stations_file)

    stations_path
    |> File.stream!()
    |> CSV.parse_stream()
    |> Stream.drop(1)  # Skip header row
    |> Stream.map(fn [_id, _name, _district, municipality, _freguesia, _bacia, _altitude, _coord_x, _coord_y, _sistema_aquifero, _estado, marker_site | _rest] -> 
      {municipality, marker_site}
    end)
    |> Stream.reject(fn {municipality, _} -> municipality == "" end)
    |> Enum.reduce(%{}, fn {municipality, id}, acc ->
      Map.update(acc, municipality, MapSet.new([id]), &MapSet.put(&1, id))
    end)
  end
end
