defmodule ElixirTutorWeb.LearningLive do
  use ElixirTutorWeb, :live_view

  alias ElixirTutor.{Learning, CodeExecutor}

  @impl true
  def mount(_params, session, socket) do
    # Get or create user based on session (session_id is guaranteed by EnsureSessionId plug)
    session_id = session["session_id"]
    {:ok, user} = Learning.get_or_create_user(session_id)

    # Get current function or select a new one
    current_function = Learning.get_random_unlearned_function(user.id)

    # Get user's progress
    completed_progress = Learning.get_user_progress(user.id)
    completed_count = Enum.count(completed_progress, & &1.completed)
    total_functions = Learning.list_enum_functions() |> length()

    # Get or create note for current function
    note =
      if current_function do
        {:ok, note} = Learning.get_or_create_user_note(user.id, current_function.id)
        note
      else
        nil
      end

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:current_function, current_function)
     |> assign(:code, "")
     |> assign(:output, nil)
     |> assign(:error, nil)
     |> assign(:success, false)
     |> assign(:completed_count, completed_count)
     |> assign(:total_count, total_functions)
     |> assign(:note, note)
     |> assign(:note_content, note && note.content || "")
     |> assign(:completed_progress, completed_progress)
     |> assign(:show_history, false)
     |> assign(:completed_attempts, %{})
     |> assign(:user_notes, [])
     |> assign(:page_title, "Learn Elixir Enum")}
  end

  @impl true
  def handle_event("run_code", %{"code" => code}, socket) do
    current_function = socket.assigns.current_function

    if current_function do
      # Validate code safety
      case CodeExecutor.validate_code(code) do
        :ok ->
          # Execute the code
          case CodeExecutor.execute(code, current_function.name) do
            {:ok, result, output, uses_function?} ->
              success = uses_function? && String.trim(code) != ""

              # If successful, save the attempt
              Learning.create_code_attempt(%{
                user_id: socket.assigns.user.id,
                enum_function_id: current_function.id,
                code: code,
                success: success,
                output: result <> "\n" <> output
              })

              # If successful, mark function as completed and update progress
              socket =
                if success do
                  Learning.complete_function(socket.assigns.user.id, current_function.id)

                  # Refresh progress
                  completed_progress = Learning.get_user_progress(socket.assigns.user.id)
                  completed_count = Enum.count(completed_progress, & &1.completed)

                  socket
                  |> assign(:code, code)
                  |> assign(:output, result)
                  |> assign(:error, nil)
                  |> assign(:success, success)
                  |> assign(:completed_count, completed_count)
                  |> assign(:completed_progress, completed_progress)
                else
                  socket
                  |> assign(:code, code)
                  |> assign(:output, result)
                  |> assign(:error, nil)
                  |> assign(:success, success)
                end

              {:noreply, socket}

            {:error, message} ->
              Learning.create_code_attempt(%{
                user_id: socket.assigns.user.id,
                enum_function_id: current_function.id,
                code: code,
                success: false,
                error_message: message
              })

              {:noreply,
               socket
               |> assign(:code, code)
               |> assign(:output, nil)
               |> assign(:error, message)
               |> assign(:success, false)}
          end

        {:error, message} ->
          {:noreply,
           socket
           |> assign(:error, message)
           |> assign(:success, false)}
      end
    else
      {:noreply, put_flash(socket, :info, "You've completed all functions!")}
    end
  end

  @impl true
  def handle_event("next_function", _params, socket) do
    current_function = socket.assigns.current_function

    if current_function && socket.assigns.success do
      # Get next random function (current is already marked as completed)
      next_function = Learning.get_random_unlearned_function(socket.assigns.user.id)

      # Get note for next function
      note =
        if next_function do
          {:ok, note} = Learning.get_or_create_user_note(socket.assigns.user.id, next_function.id)
          note
        else
          nil
        end

      {:noreply,
       socket
       |> assign(:current_function, next_function)
       |> assign(:code, "")
       |> assign(:output, nil)
       |> assign(:error, nil)
       |> assign(:success, false)
       |> assign(:note, note)
       |> assign(:note_content, note && note.content || "")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_note", %{"note" => note_content}, socket) do
    note = socket.assigns.note

    if note do
      Learning.update_user_note(note, %{content: note_content})

      {:noreply, assign(socket, :note_content, note_content)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_history", _params, socket) do
    show_history = !socket.assigns.show_history

    # If showing history, load the completed attempts and notes
    socket =
      if show_history do
        completed_attempts = Learning.get_completed_attempts(socket.assigns.user.id)
        notes = Learning.get_user_notes_with_functions(socket.assigns.user.id)

        socket
        |> assign(:show_history, true)
        |> assign(:completed_attempts, completed_attempts)
        |> assign(:user_notes, notes)
      else
        socket
        |> assign(:show_history, false)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("open_function", %{"id" => function_id_str}, socket) do
    function_id = String.to_integer(function_id_str)

    # Get the function
    function = Learning.get_enum_function!(function_id)

    # Get the user's last successful code attempt for this function
    code =
      case Learning.get_completed_attempts(socket.assigns.user.id) do
        %{^function_id => attempt} when not is_nil(attempt) -> attempt.code
        _ -> ""
      end

    # Get or create note for this function
    {:ok, note} = Learning.get_or_create_user_note(socket.assigns.user.id, function_id)

    {:noreply,
     socket
     |> assign(:current_function, function)
     |> assign(:code, code)
     |> assign(:note, note)
     |> assign(:note_content, note.content || "")
     |> assign(:show_history, false)
     |> assign(:output, nil)
     |> assign(:error, nil)
     |> assign(:success, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <div class="container mx-auto px-4 py-8">
        <!-- Header -->
        <div class="mb-8">
          <div class="flex items-center justify-between mb-4">
            <h1 class="text-4xl font-bold text-indigo-900">
              ElixirTutor - Master the Enum Module
            </h1>
            <%= if @completed_count > 0 do %>
              <button
                type="button"
                phx-click="toggle_history"
                class="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white font-semibold rounded-lg shadow-md transition-colors"
              >
                <%= if @show_history do %>
                  Hide History
                <% else %>
                  View History (<%= @completed_count %>)
                <% end %>
              </button>
            <% end %>
          </div>
          <div class="flex items-center gap-4">
            <div class="flex-1 bg-white rounded-full h-4 overflow-hidden shadow-inner">
              <div
                class="bg-gradient-to-r from-green-400 to-blue-500 h-full transition-all duration-500"
                style={"width: #{progress_percentage(@completed_count, @total_count)}%"}
              >
              </div>
            </div>
            <span class="text-sm font-semibold text-indigo-700">
              <%= @completed_count %>/<%= @total_count %> functions learned
            </span>
          </div>
        </div>

        <%= if @show_history do %>
          <!-- History View -->
          <div class="bg-white rounded-lg shadow-lg p-6">
            <h2 class="text-2xl font-bold text-indigo-900 mb-6">
              Your Learning History
            </h2>

            <%= if length(@completed_progress) > 0 do %>
              <div class="space-y-4">
                <%= for progress <- Enum.filter(@completed_progress, & &1.completed) do %>
                  <div class="border border-gray-200 rounded-lg p-4 hover:border-indigo-400 hover:shadow-md transition-all cursor-pointer">
                    <div class="flex items-start justify-between mb-3">
                      <div class="flex-1">
                        <h3 class="text-lg font-bold text-indigo-600">
                          Enum.<%= progress.enum_function.name %>/<%= progress.enum_function.arity %>
                        </h3>
                        <%= if progress.completed_at do %>
                          <p class="text-xs text-gray-500 mt-1">
                            Completed: <%= Calendar.strftime(progress.completed_at, "%B %d, %Y at %I:%M %p") %>
                          </p>
                        <% end %>
                      </div>
                      <button
                        type="button"
                        phx-click="open_function"
                        phx-value-id={progress.enum_function_id}
                        class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold rounded-lg shadow-sm transition-colors"
                      >
                        Open
                      </button>
                    </div>

                    <!-- Your Code -->
                    <%= if Map.has_key?(@completed_attempts, progress.enum_function_id) && @completed_attempts[progress.enum_function_id] do %>
                      <div class="mb-3">
                        <h4 class="text-sm font-semibold text-gray-700 mb-2">Your Code:</h4>
                        <pre class="bg-gray-900 text-green-400 p-3 rounded text-sm overflow-x-auto"><code><%= @completed_attempts[progress.enum_function_id].code %></code></pre>
                      </div>
                    <% end %>

                    <!-- Your Notes -->
                    <%= if note = Enum.find(@user_notes, fn n -> n.enum_function_id == progress.enum_function_id end) do %>
                      <%= if note.content && String.trim(note.content) != "" do %>
                        <div>
                          <h4 class="text-sm font-semibold text-gray-700 mb-2">Your Notes:</h4>
                          <div class="bg-yellow-50 border border-yellow-200 rounded p-3 text-sm whitespace-pre-wrap">
                            <%= note.content %>
                          </div>
                        </div>
                      <% end %>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% else %>
              <p class="text-gray-500 text-center py-8">
                You haven't completed any functions yet. Start learning to build your history!
              </p>
            <% end %>
          </div>
        <% else %>
          <%= if @current_function do %>
            <!-- Main Learning Interface -->
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
              <!-- Left Column: Function Info & Notes -->
              <div class="lg:col-span-1 space-y-6">
                <!-- Function Display -->
                <div class="bg-white rounded-lg shadow-lg p-6">
                  <div class="mb-4">
                    <h2 class="text-2xl font-bold text-indigo-600">
                      Enum.<%= @current_function.name %>/<%= @current_function.arity %>
                    </h2>
                  </div>

                  <div class="prose prose-sm max-w-none">
                    <h3 class="text-sm font-semibold text-gray-700 mb-2">Documentation:</h3>
                    <p class="text-gray-600 text-sm whitespace-pre-line">
                      <%= String.split(@current_function.documentation, "## Examples") |> hd() %>
                    </p>
                  </div>

                  <div class="mt-4">
                    <h3 class="text-sm font-semibold text-gray-700 mb-2">Examples:</h3>
                    <pre class="bg-gray-50 border border-gray-200 rounded p-3 text-xs overflow-x-auto"><code><%= @current_function.examples %></code></pre>
                  </div>
                </div>

                <!-- Notes Panel -->
                <div class="bg-white rounded-lg shadow-lg p-6">
                  <h3 class="text-lg font-bold text-indigo-600 mb-3">
                    📝 Your Notes
                  </h3>
                  <form phx-change="update_note" phx-debounce="500">
                    <textarea
                      class="w-full h-32 px-3 py-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                      placeholder="Write your notes here... (auto-saved)"
                      name="note"
                    ><%= @note_content %></textarea>
                  </form>
                  <p class="text-xs text-gray-500 mt-2">
                    💡 Notes are automatically saved
                  </p>
                </div>
              </div>

              <!-- Right Column: Code Editor & Output -->
              <div class="lg:col-span-2 space-y-6">
                <!-- Code Editor -->
                <div class="bg-white rounded-lg shadow-lg p-6">
                  <h3 class="text-lg font-bold text-indigo-600 mb-3">
                    💻 Try It Yourself
                  </h3>
                  <form phx-submit="run_code">
                    <textarea
                      name="code"
                      class="w-full h-48 px-4 py-3 font-mono text-sm bg-gray-900 text-green-400 rounded-lg border-2 border-gray-700 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500"
                      placeholder={"# Write code using Enum.#{@current_function.name}/#{@current_function.arity}\n\nEnum.#{@current_function.name}(...)\n"}
                    ><%= @code %></textarea>

                    <div class="mt-4 flex items-center gap-3">
                      <button
                        type="submit"
                        class="px-6 py-3 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-lg shadow-md transition-colors"
                      >
                        ▶ Run Code
                      </button>

                      <%= if @success do %>
                        <button
                          type="button"
                          phx-click="next_function"
                          class="px-6 py-3 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg shadow-md transition-colors animate-pulse"
                        >
                          ✓ Next Function →
                        </button>
                      <% end %>
                    </div>
                  </form>
                </div>

                <!-- Output Console -->
                <div class="bg-white rounded-lg shadow-lg p-6">
                  <h3 class="text-lg font-bold text-indigo-600 mb-3">
                    📤 Output
                  </h3>

                  <%= if @success do %>
                    <div class="bg-green-50 border-l-4 border-green-500 p-4 mb-4">
                      <div class="flex items-center">
                        <div class="text-green-700">
                          <p class="font-bold">✓ Success!</p>
                          <p class="text-sm">
                            Great work! You used Enum.<%= @current_function.name %>/<%= @current_function.arity %> correctly.
                            Click "Next Function" to continue.
                          </p>
                        </div>
                      </div>
                    </div>
                  <% end %>

                  <%= if @error do %>
                    <div class="bg-red-50 border-l-4 border-red-500 p-4 mb-4">
                      <div class="text-red-700">
                        <p class="font-bold">✗ Error</p>
                        <pre class="text-sm mt-2 whitespace-pre-wrap"><%= @error %></pre>
                      </div>
                    </div>
                  <% end %>

                  <%= if @output do %>
                    <div class="bg-gray-50 border border-gray-200 rounded-lg p-4">
                      <p class="text-xs font-semibold text-gray-600 mb-2">Result:</p>
                      <pre class="text-sm text-gray-800 font-mono whitespace-pre-wrap"><%= @output %></pre>
                    </div>
                  <% else %>
                    <div class="text-gray-400 text-center py-8">
                      <p class="text-sm">Write and run code to see the output here</p>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% else %>
            <!-- All Functions Completed -->
            <div class="bg-white rounded-lg shadow-2xl p-12 text-center">
              <div class="text-6xl mb-6">🎉</div>
              <h2 class="text-3xl font-bold text-indigo-900 mb-4">
                Congratulations!
              </h2>
              <p class="text-xl text-gray-600 mb-8">
                You've learned all <%= @total_count %> Enum functions!
              </p>
              <p class="text-gray-500">
                You're now an Elixir Enum expert! Keep practicing to master them all.
              </p>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  defp progress_percentage(completed, total) when total > 0 do
    (completed / total * 100) |> Float.round(1)
  end

  defp progress_percentage(_, _), do: 0
end
