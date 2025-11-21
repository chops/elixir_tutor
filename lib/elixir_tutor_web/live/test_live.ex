defmodule ElixirTutorWeb.TestLive do
  use ElixirTutorWeb, :live_view

  alias ElixirTutor.Learning

  @impl true
  def mount(_params, _session, socket) do
    # Get all enum functions from the database
    enum_functions = Learning.list_enum_functions()

    {:ok,
     socket
     |> assign(:enum_functions, enum_functions)
     |> assign(:page_title, "Database Test")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 py-10 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-4xl">
        <h1 class="text-4xl font-bold text-zinc-900 mb-8">
          ElixirTutor Database Test
        </h1>

        <div class="bg-green-50 border border-green-200 rounded-lg p-4 mb-8">
          <p class="text-green-800 font-semibold">
            ✅ Database Connection: Working
          </p>
          <p class="text-green-700 mt-1">
            Found <%= length(@enum_functions) %> Enum functions in the database
          </p>
        </div>

        <h2 class="text-2xl font-semibold text-zinc-800 mb-4">
          Seeded Enum Functions
        </h2>

        <div class="space-y-4">
          <%= for func <- @enum_functions do %>
            <div class="bg-white border border-zinc-200 rounded-lg p-6 shadow-sm hover:shadow-md transition-shadow">
              <div class="flex items-center justify-between mb-3">
                <h3 class="text-xl font-bold text-blue-600">
                  Enum.<%= func.name %>/<%= func.arity %>
                </h3>
                <span class="text-sm text-zinc-500">
                  ID: <%= func.id %>
                </span>
              </div>

              <div class="mb-4">
                <h4 class="text-sm font-semibold text-zinc-700 mb-2">Documentation:</h4>
                <p class="text-zinc-600 text-sm whitespace-pre-line">
                  <%= func.documentation %>
                </p>
              </div>

              <div>
                <h4 class="text-sm font-semibold text-zinc-700 mb-2">Examples:</h4>
                <pre class="bg-zinc-50 border border-zinc-200 rounded p-3 text-sm overflow-x-auto"><code><%= func.examples %></code></pre>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
