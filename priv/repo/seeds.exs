# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias ElixirTutor.Repo
alias ElixirTutor.Learning.EnumFunction

# Clear existing enum functions (for development)
Repo.delete_all(EnumFunction)

IO.puts("Extracting Enum function documentation from Elixir...")

# Helper function to generate basic examples
generate_examples = fn name, _arity ->
  """
  iex> Enum.#{name}(...)
  # Try this function yourself!
  """
end

# Get all exported functions from the Enum module
enum_functions =
  Enum.__info__(:functions)
  |> Enum.map(fn {name, arity} ->
    # Get documentation for each function
    case Code.fetch_docs(Enum) do
      {:docs_v1, _, :elixir, _, _, _, functions} ->
        # Find the specific function documentation
        doc_entry =
          Enum.find(functions, fn
            {{:function, ^name, ^arity}, _, _, _, _} -> true
            _ -> false
          end)

        case doc_entry do
          {{:function, ^name, ^arity}, _line, _signature, doc_content, _metadata} ->
            # Extract documentation text
            documentation =
              case doc_content do
                %{"en" => doc_text} -> doc_text
                :hidden -> "Documentation not available."
                :none -> "No documentation available."
                _ -> "Documentation not available."
              end

            # Format the documentation nicely
            formatted_doc = String.trim(documentation)

            # Create simple examples based on the function name
            examples = generate_examples.(name, arity)

            %{
              name: to_string(name),
              arity: arity,
              documentation: formatted_doc,
              examples: examples
            }

          nil ->
            %{
              name: to_string(name),
              arity: arity,
              documentation: "Documentation not available.",
              examples: generate_examples.(name, arity)
            }
        end

      _ ->
        %{
          name: to_string(name),
          arity: arity,
          documentation: "Documentation not available.",
          examples: generate_examples.(name, arity)
        }
    end
  end)
  |> Enum.reject(&is_nil/1)

IO.puts("Seeding #{length(enum_functions)} Enum functions...")

# Insert all functions
Enum.each(enum_functions, fn attrs ->
  %EnumFunction{}
  |> EnumFunction.changeset(attrs)
  |> Repo.insert!()
end)

IO.puts("✅ Successfully seeded #{length(enum_functions)} Enum functions!")
