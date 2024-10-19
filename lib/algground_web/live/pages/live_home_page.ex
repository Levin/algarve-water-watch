defmodule AlggroundWeb.LiveHomePage do
  use AlggroundWeb, :live_view

  @region_names [
    "Albufeira",
    "Alcoutim",
    "Aljezur",
    "Castro Marim",
    "Faro",
    "Lagoa",
    "Lagos",
    "Loulé",
    "Monchique",
    "Olhão",
    "Portimão",
    "São Brás de Alportel",
    "Silves",
    "Tavira",
    "Vila do Bispo",
    "Vila Real de Santo António"
  ]

  def mount(_params, _session, socket) do
    regions =
      Enum.map(@region_names, fn region ->
        %{
          region: region,
          groundwater: trunc(:rand.uniform() * 100),
          rainfall: trunc(:rand.uniform() * 100),
          reservoir: trunc(:rand.uniform() * 10_000_000)
        }
      end)

    Process.send_after(self(), "new_values", 2_000)

    {:ok,
     socket
     |> assign(:date, Date.utc_today())
     |> assign(:regions, regions)
     |> assign(:groundwater, trunc(:rand.uniform() * 100))
     |> assign(:rainfall, trunc(:rand.uniform() * 100))
     |> assign(:reservoirs, trunc(:rand.uniform() * 10_000_000))}
  end

  def handle_info("new_values", socket) do
    Process.send_after(self(), "new_values", 2_000)

    regions =
      Enum.map(@region_names, fn region ->
        %{
          region: region,
          groundwater: trunc(:rand.uniform() * 100),
          rainfall: trunc(:rand.uniform() * 100),
          reservoir: trunc(:rand.uniform() * 10_000_000)
        }
      end)

    {:noreply,
     socket
     |> assign(:regions, regions)
     |> assign(:date, Date.add(socket.assigns.date, 31))
     |> assign(:groundwater, trunc(:rand.uniform() * 100))
     |> assign(:rainfall, trunc(:rand.uniform() * 100))
     |> assign(:reservoirs, trunc(:rand.uniform() * 10_000_000))}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="bg-gray-50 py-12 sm:py-6 rounded-lg">
        <div class="mx-auto max-w-2xl px-6 lg:max-w-7xl lg:px-8">
          <p class="mx-auto max-w-lg text-pretty text-center font-medium tracking-tight text-gray-400 text-3xl">
            <%= @date %>
          </p>
          <p class="mx-auto max-w-lg text-pretty text-center  font-medium tracking-tight text-gray-950 text-3xl">
            Albufeira
          </p>
          <p class="mx-auto max-w-lg text-pretty text-center text-4xl font-medium tracking-tight text-gray-950 sm:text-3xl ">
            <%= display_groundwater(assigns) %>
          </p>
          <p class="mx-auto max-w-lg text-pretty text-center font-sm tracking-tight text-gray-400 text-sm">
            Ground Water Level
          </p>
          <div class="mt-10 grid gap-4 sm:mt-4 ">
            <div class="relative mb-4">
              <div class="absolute inset-px bg-white rounded-t-[2rem]"></div>
              <div class="relative flex h-full flex-col overflow-hidden rounded-[calc(2rem+1px)]">
                <div class="flex justify-evenly mb-8">
                  <div class="px-8 pt-8 sm:px-10 sm:pt-10">
                    <p class="mt-2 text-md font-medium tracking-tight text-gray-950 max-lg:text-center">
                      Rainfall
                    </p>
                    <p class="mt-2 max-w-lg text-lg/6 text-gray-600 max-lg:text-center text-indigo-800">
                      <%= display_rainfall(assigns) %>
                    </p>
                  </div>
                  <div class="px-8 pt-8 sm:px-10 sm:pt-10">
                    <p class="mt-2 text-md font-medium tracking-tight text-gray-950 max-lg:text-center">
                      Reservoirs
                    </p>
                    <p class="mt-2 max-w-lg text-lg/6 text-gray-600 max-lg:text-center text-indigo-800">
                      <%= display_reservoirs(assigns) %>
                    </p>
                  </div>
                </div>
              </div>
              <div class="pointer-events-none absolute inset-px rounded-lg shadow ring-1 ring-black/5 max-lg:rounded-t-[2rem]">
              </div>
            </div>
          </div>
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

  defp display_groundwater(assigns) do
    cond do
      assigns.groundwater >= 150 ->
        ~H"""
        <p class="mt-2 mx-auto flex justify-center text-lg/6 text-green-600 ">
          <%= @groundwater %>m
        </p>
        """

      assigns.groundwater < 150 and assigns.groundwater >= 50 ->
        ~H"""
        <p class="mt-2 mx-auto flex justify-center text-lg/6 text-green-600 ">
          <%= @groundwater %>m
        </p>
        """

      assigns.groundwater < 50 ->
        ~H"""
        <p class="mt-2 mx-auto flex justify-center text-lg/6 text-green-600 ">
          <%= @groundwater %>m
        </p>
        """
    end
  end

  defp display_rainfall(assigns) do
    cond do
      assigns.rainfall >= 80 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-green-600 max-lg:text-center">
          <%= @rainfall %>mm
        </p>
        """

      assigns.rainfall < 80 and assigns.rainfall >= 30 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-amber-500 max-lg:text-center">
          <%= @rainfall %>mm
        </p>
        """

      assigns.rainfall < 30 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-red-600 max-lg:text-center">
          <%= @rainfall %>mm
        </p>
        """
    end
  end

  defp display_reservoirs(assigns) do
    cond do
      assigns.reservoirs >= 6_000_000 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-green-600 max-lg:text-center">
          <%= @reservoirs %>l
        </p>
        """

      assigns.reservoirs < 6_000_000 and assigns.reservoirs >= 1_200_000 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-amber-500 max-lg:text-center">
          <%= @reservoirs %>l
        </p>
        """

      assigns.reservoirs < 1_200_000 ->
        ~H"""
        <p class="mt-2 max-w-lg text-lg/6 text-red-600 max-lg:text-center">
          <%= @reservoirs %>l
        </p>
        """
    end
  end
end
