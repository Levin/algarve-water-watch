defmodule AlggroundWeb.FeedbackPage do
  use AlggroundWeb, :live_view

  @doc """
    in this liveview, we want to gather feedback by our users.
    in order to do that, we give them a feedback form which is hold by this liveview.
    we want to give the user a very nice experience filling out the form, so we follow the latest ux choices by leading companies.
    the fields we want the user to fill out are:
      - email: which is the email of the user, :email  
      - missing_metrics: which is a comma separated list of metrics we do not have data for, :textarea
      - best_feature: which is the feature we believe is the best, :textarea
      - missing_feature: which is a description of the feature we believe is the best which we do not have data for, :textarea
      - location_missing: which is yes if the location of the feature we believe is the best we do not have data for, :textarea
      - location_missing_details: which is the description of the location where we do not have data for the best feature, :textarea
      - map_essential: which is yes if the map is essential to understand the feature we believe is the best, :textarea
      - map_essential_details: which is the description of the map that is essential to understand the feature we believe is the best, :textarea

    the user does not need to fill out all the items in the form. at least we require these options:
      - missing_metrics: which is a comma separated list of metrics we do not have data for
      - missing_feature: which is a description of the feature we believe is the best which we do not have data for
      - location_missing: which is yes if the location of the feature we believe is the best we do not have data for
    
    in order to make sure that these fields are filled out in a fast and easy way, we place them at the beginning and group them together.
    we also validate each field

    the mount function should account for all these values and also hold the error that gets updated in case we are missing a required item.
    the users email should be places atop but is optional for them to give to us.
    the validate function will not validate instantly but only when the user hits the submit button OR when there where 5 seconds of no changes to the form. then we call the validate function.

    In order to save the feedback, we safe the answers to the questions in a csv file. the headers of that file should be in the according order that we ask the questions.

    also in case users want to go back to the homepage, we navigate to that page. give them a arrow back in the top left corner that links to the homepage.

  """
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       :form,
       to_form(%{
         "email" => "",
         "missing_metrics" => "",
         "best_feature" => "",
         "missing_feature" => "",
         "location_missing" => "no",
         "location_missing_details" => "",
         "map_essential" => "no",
         "map_essential_details" => ""
       })
     )
     |> assign(:errors, %{})
     |> assign(:validation_timer, nil)}
  end

  def handle_event("save", %{"feedback" => feedback}, socket) do
    case validate_feedback(feedback) do
      {:ok, validated_feedback} ->
        save_feedback_to_csv(validated_feedback)

        {:noreply,
         socket
         |> put_flash(:info, "Thank you for your feedback!")
         |> push_navigate(to: ~p"/")}

      {:error, errors} ->
        {:noreply,
         socket
         |> assign(:errors, errors)
         |> assign(:form, to_form(feedback))}
    end
  end

  def handle_event("form_changed", %{"feedback" => feedback}, socket) do
    # Cancel any existing timer
    if socket.assigns.validation_timer, do: Process.cancel_timer(socket.assigns.validation_timer)
    
    # Set a new timer for validation after 5 seconds
    timer_ref = Process.send_after(self(), {:validate_form, feedback}, 5000)
    
    {:noreply,
     socket
     |> assign(:form, to_form(feedback))
     |> assign(:validation_timer, timer_ref)}
  end

  def handle_event("validate", %{"feedback" => feedback}, socket) do
    case validate_feedback(feedback) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:errors, %{})
         |> assign(:form, to_form(feedback))}

      {:error, errors} ->
        {:noreply,
         socket
         |> assign(:errors, errors)
         |> assign(:form, to_form(feedback))}
    end
  end

  def handle_event("update_location_missing", %{"value" => value}, socket) do
    current_data = socket.assigns.form.params
    updated_data = Map.put(current_data, "location_missing", value)

    {:noreply, assign(socket, :form, to_form(updated_data))}
  end

  def handle_event("update_map_essential", %{"value" => value}, socket) do
    current_data = socket.assigns.form.params
    updated_data = Map.put(current_data, "map_essential", value)

    {:noreply, assign(socket, :form, to_form(updated_data))}
  end

  def handle_info({:validate_form, feedback}, socket) do
    case validate_feedback(feedback) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:errors, %{})
         |> assign(:validation_timer, nil)}

      {:error, errors} ->
        {:noreply,
         socket
         |> assign(:errors, errors)
         |> assign(:validation_timer, nil)}
    end
  end

  defp validate_feedback(feedback) do
    errors = %{}

    errors =
      if String.length(feedback["email"] || "") > 0 && !String.match?(feedback["email"], ~r/^[^\s]+@[^\s]+\.[^\s]+$/) do
        Map.put(errors, :email, "Please provide a valid email address")
      else
        errors
      end

    errors =
      if String.length(feedback["missing_metrics"] || "") < 3 do
        Map.put(errors, :missing_metrics, "Please provide at least 3 characters")
      else
        errors
      end

    errors =
      if String.length(feedback["best_feature"] || "") < 3 do
        Map.put(errors, :best_feature, "Please provide at least 3 characters")
      else
        errors
      end

    errors =
      if String.length(feedback["missing_feature"] || "") < 3 do
        Map.put(errors, :missing_feature, "Please provide at least 3 characters")
      else
        errors
      end

    errors =
      if feedback["location_missing"] == "yes" &&
           String.length(feedback["location_missing_details"] || "") < 3 do
        Map.put(
          errors,
          :location_missing_details,
          "Please provide details about the missing location"
        )
      else
        errors
      end

    errors =
      if feedback["map_essential"] == "yes" &&
           String.length(feedback["map_essential_details"] || "") < 3 do
        Map.put(
          errors,
          :map_essential_details,
          "Please explain why you consider the map essential"
        )
      else
        errors
      end

    if map_size(errors) == 0 do
      {:ok, feedback}
    else
      {:error, errors}
    end
  end

  defp save_feedback_to_csv(feedback) do
    csv_path = "feedback_data.csv"

    headers = [
      "Email",
      "Missing Metrics",
      "Best Feature",
      "Missing Feature",
      "Location Missing",
      "Location Missing Details",
      "Map Essential",
      "Map Essential Details"
    ]

    row_data = [
      feedback["email"] || "",
      feedback["missing_metrics"] || "",
      feedback["best_feature"] || "",
      feedback["missing_feature"] || "",
      feedback["location_missing"] || "",
      feedback["location_missing_details"] || "",
      feedback["map_essential"] || "",
      feedback["map_essential_details"] || ""
    ]

    file_exists? = File.exists?(csv_path)

    rows =
      if file_exists? do
        # Read existing content
        File.stream!(csv_path)
        |> CSV.decode!()
        |> Enum.to_list()
      else
        # Start with headers if file doesn't exist
        [headers]
      end

    # Append new row
    rows = rows ++ [row_data]

    # Write all rows back to file
    file = File.open!(csv_path, [:write, :utf8])

    CSV.encode(rows)
    |> Enum.each(&IO.write(file, &1))

    File.close(file)
  end

  defp escape_csv_field(nil), do: ~s("")

  defp escape_csv_field(field) do
    # Replace " with ""
    field = String.replace(field, ~s("), ~s(""))

    if String.contains?(field, [",", "\n", "\r", "\""]) do
      # Wrap in quotes if contains special chars
      ~s("#{field}")
    else
      field
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl px-6 py-8 relative">
      <div class="absolute top-2 left-2">
        <a href="/" class="text-indigo-600 hover:text-indigo-800 flex items-center">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
          <span>Back to Home</span>
        </a>
      </div>
      
      <h2 class="text-2xl font-bold text-indigo-800 mb-8 mt-8">Your Feedback Matters!</h2>

      <.form for={@form} phx-submit="save" phx-change="form_changed" class="space-y-6">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Your Email (optional)
          </label>
          <input
            type="email"
            name="feedback[email]"
            value={Phoenix.HTML.Form.input_value(@form, "email")}
            class={"block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 #{if @errors[:email], do: "border-red-500"}"}
          />
          <%= if @errors[:email] do %>
            <p class="mt-1 text-sm text-red-600"><%= @errors[:email] %></p>
          <% end %>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Which metrics are missing?
          </label>
          <textarea
            name="feedback[missing_metrics]"
            rows="3"
            class={"block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 #{if @errors[:missing_metrics], do: "border-red-500"}"}
          ><%= Phoenix.HTML.Form.input_value(@form, "missing_metrics") %></textarea>
          <%= if @errors[:missing_metrics] do %>
            <p class="mt-1 text-sm text-red-600"><%= @errors[:missing_metrics] %></p>
          <% end %>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            What is the best feature of the app?
          </label>
          <textarea
            name="feedback[best_feature]"
            rows="3"
            class={"block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 #{if @errors[:best_feature], do: "border-red-500"}"}
          ><%= Phoenix.HTML.Form.input_value(@form, "best_feature") %></textarea>
          <%= if @errors[:best_feature] do %>
            <p class="mt-1 text-sm text-red-600"><%= @errors[:best_feature] %></p>
          <% end %>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            What feature do you miss?
          </label>
          <textarea
            name="feedback[missing_feature]"
            rows="3"
            class={"block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 #{if @errors[:missing_feature], do: "border-red-500"}"}
          ><%= Phoenix.HTML.Form.input_value(@form, "missing_feature") %></textarea>
          <%= if @errors[:missing_feature] do %>
            <p class="mt-1 text-sm text-red-600"><%= @errors[:missing_feature] %></p>
          <% end %>
        </div>

        <div class="space-y-4">
          <label class="block text-sm font-medium text-gray-700">
            Is your location missing?
          </label>
          <div class="flex items-center space-x-4">
            <label class="inline-flex items-center">
              <input
                type="radio"
                name="feedback[location_missing]"
                value="yes"
                phx-click="update_location_missing"
                phx-value-value="yes"
                class="h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-500"
                checked={Phoenix.HTML.Form.input_value(@form, "location_missing") == "yes"}
              />
              <span class="ml-2">Yes</span>
            </label>
            <label class="inline-flex items-center">
              <input
                type="radio"
                name="feedback[location_missing]"
                value="no"
                phx-click="update_location_missing"
                phx-value-value="no"
                class="h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-500"
                checked={Phoenix.HTML.Form.input_value(@form, "location_missing") == "no"}
              />
              <span class="ml-2">No</span>
            </label>
          </div>
          <%= if Phoenix.HTML.Form.input_value(@form, "location_missing") == "yes" do %>
            <div class="mt-2">
              <textarea
                name="feedback[location_missing_details]"
                rows="3"
                placeholder="Please tell us which location is missing..."
                class={"block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 #{if @errors[:location_missing_details], do: "border-red-500"}"}
              ><%= Phoenix.HTML.Form.input_value(@form, "location_missing_details") %></textarea>
              <%= if @errors[:location_missing_details] do %>
                <p class="mt-1 text-sm text-red-600"><%= @errors[:location_missing_details] %></p>
              <% end %>
            </div>
          <% end %>
        </div>

        <div class="space-y-4">
          <label class="block text-sm font-medium text-gray-700">
            Do you consider map view essential?
          </label>
          <div class="flex items-center space-x-4">
            <label class="inline-flex items-center">
              <input
                type="radio"
                name="feedback[map_essential]"
                value="yes"
                phx-click="update_map_essential"
                phx-value-value="yes"
                class="h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-500"
                checked={Phoenix.HTML.Form.input_value(@form, "map_essential") == "yes"}
              />
              <span class="ml-2">Yes</span>
            </label>
            <label class="inline-flex items-center">
              <input
                type="radio"
                name="feedback[map_essential]"
                value="no"
                phx-click="update_map_essential"
                phx-value-value="no"
                class="h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-500"
                checked={Phoenix.HTML.Form.input_value(@form, "map_essential") == "no"}
              />
              <span class="ml-2">No</span>
            </label>
          </div>
          <%= if Phoenix.HTML.Form.input_value(@form, "map_essential") == "yes" do %>
            <div class="mt-2">
              <textarea
                name="feedback[map_essential_details]"
                rows="3"
                placeholder="Please tell us why you consider the map view essential..."
                class={"block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 #{if @errors[:map_essential_details], do: "border-red-500"}"}
              ><%= Phoenix.HTML.Form.input_value(@form, "map_essential_details") %></textarea>
              <%= if @errors[:map_essential_details] do %>
                <p class="mt-1 text-sm text-red-600"><%= @errors[:map_essential_details] %></p>
              <% end %>
            </div>
          <% end %>
        </div>

        <div>
          <button
            type="submit"
            class="w-full rounded-md bg-indigo-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          >
            Send Feedback
          </button>
        </div>
      </.form>
    </div>
    """
  end
end
