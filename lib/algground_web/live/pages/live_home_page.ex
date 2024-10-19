defmodule AlggroundWeb.LiveHomePage do
  use AlggroundWeb, :live_view

  def mount(_params, _session, socket) do
    regions = [
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

    {:ok,
     socket
     |> assign(:regions, regions)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="bg-gray-50 py-12 sm:py-6 rounded-lg">
        <div class="mx-auto max-w-2xl px-6 lg:max-w-7xl lg:px-8">
          <p class="mx-auto max-w-lg text-pretty text-center  font-medium tracking-tight text-gray-950 text-3xl">
            Albufeira
          </p>
          <p class="mx-auto max-w-lg text-pretty text-center text-4xl font-medium tracking-tight text-gray-950 sm:text-3xl text-indigo-800">
            20mm
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
              <div class="pointer-events-none absolute inset-px rounded-lg shadow ring-1 ring-black/5 max-lg:rounded-t-[2rem]">
              </div>
            </div>
          </div>
          <div class="relative">
            <div class="absolute inset-px rounded-lg bg-white lg:rounded-l-[2rem]"></div>
            <div class="relative flex h-full flex-col overflow-hidden rounded-[calc(theme(borderRadius.lg)+1px)] lg:rounded-l-[calc(2rem+1px)]">
              <div class="px-8 pb-3 pt-8 sm:px-10 sm:pb-0 sm:pt-10">
                <p class="mt-2 text-lg/7 font-medium tracking-tight text-gray-950 max-lg:text-center">
                  See other Regions
                </p>

                <%= for region <- @regions do %>
                  <.live_component
                    module={AlggroundWeb.Components.Region}
                    region={region}
                    id={region <> "#{System.unique_integer()}"}
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
end
