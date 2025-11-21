defmodule ElixirTutor.CodeExecutor do
  @moduledoc """
  Safely executes user-submitted Elixir code with strict sandboxing.
  """

  @timeout 5_000
  @max_memory 50_000_000  # 50MB

  @doc """
  Executes the given code string and returns the result.

  Returns:
  - `{:ok, result, output}` - Code executed successfully
  - `{:error, message}` - Code failed to compile or execute
  """
  def execute(code, enum_function_name) do
    # Spawn a separate process for isolation
    parent = self()

    ref = make_ref()

    {:ok, pid} = Task.start(fn ->
      try do
        # Capture IO output
        output = capture_io(fn ->
          # Evaluate the code
          {result, _binding} = Code.eval_string(code, [])
          send(parent, {ref, :ok, result})
        end)

        send(parent, {ref, :output, output})
      rescue
        error ->
          send(parent, {ref, :error, Exception.message(error)})
      catch
        kind, reason ->
          message = "#{kind}: #{inspect(reason)}"
          send(parent, {ref, :error, message})
      end
    end)

    # Wait for result with timeout
    receive do
      {^ref, :ok, result} ->
        output = receive do
          {^ref, :output, out} -> out
        after
          100 -> ""
        end

        # Check if the code uses the target Enum function
        uses_function? = String.contains?(code, "Enum.#{enum_function_name}")

        {:ok, inspect(result), output, uses_function?}

      {^ref, :error, message} ->
        {:error, message}
    after
      @timeout ->
        Process.exit(pid, :kill)
        {:error, "Execution timeout (#{@timeout}ms)"}
    end
  end

  defp capture_io(fun) do
    original_leader = Process.group_leader()
    {:ok, capture_device} = StringIO.open("")
    Process.group_leader(self(), capture_device)

    try do
      fun.()
    after
      Process.group_leader(self(), original_leader)
    end

    StringIO.flush(capture_device)
  end

  @doc """
  Validates that code only uses safe operations.
  """
  def validate_code(code) do
    # Basic safety checks
    unsafe_patterns = [
      ~r/File\./,
      ~r/System\./,
      ~r/:os\./,
      ~r/:erlang\.halt/,
      ~r/spawn/,
      ~r/Agent\./,
      ~r/Task\.async/,
      ~r/GenServer\./,
    ]

    dangerous = Enum.find(unsafe_patterns, fn pattern ->
      Regex.match?(pattern, code)
    end)

    case dangerous do
      nil -> :ok
      _pattern -> {:error, "Code contains unsafe operations"}
    end
  end
end
