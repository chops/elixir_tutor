# Script for populating the database with official Enum functions from Elixir 1.19.3
# Based on https://hexdocs.pm/elixir/1.19.3/Enum.html

alias ElixirTutor.Repo
alias ElixirTutor.Learning.EnumFunction

# Clear existing enum functions
Repo.delete_all(EnumFunction)

IO.puts("Seeding official Elixir 1.19.3 Enum functions...")

# Official Enum functions (88 total)
# We'll use the highest arity version for functions with default arguments
enum_functions = [
  {:"all?", 2},
  {:"all?", 1},
  {:"any?", 2},
  {:"any?", 1},
  {:at, 3},
  {:chunk_by, 2},
  {:chunk_every, 4},
  {:chunk_every, 2},
  {:chunk_while, 4},
  {:concat, 1},
  {:concat, 2},
  {:count_until, 3},
  {:count_until, 2},
  {:count, 2},
  {:count, 1},
  {:dedup_by, 2},
  {:dedup, 1},
  {:drop_every, 2},
  {:drop_while, 2},
  {:drop, 2},
  {:each, 2},
  {:"empty?", 1},
  {:"fetch!", 2},
  {:fetch, 2},
  {:filter, 2},
  {:find_index, 2},
  {:find_value, 3},
  {:find, 3},
  {:flat_map_reduce, 3},
  {:flat_map, 2},
  {:frequencies_by, 2},
  {:frequencies, 1},
  {:group_by, 3},
  {:intersperse, 2},
  {:into, 3},
  {:into, 2},
  {:join, 2},
  {:map_every, 3},
  {:map_intersperse, 3},
  {:map_join, 3},
  {:map_reduce, 3},
  {:map, 2},
  {:max_by, 4},
  {:max, 3},
  {:"member?", 2},
  {:min_by, 4},
  {:min_max_by, 4},
  {:min_max, 2},
  {:min, 3},
  {:product_by, 2},
  {:product, 1},
  {:random, 1},
  {:reduce_while, 3},
  {:reduce, 3},
  {:reduce, 2},
  {:reject, 2},
  {:reverse_slice, 3},
  {:reverse, 2},
  {:reverse, 1},
  {:scan, 3},
  {:scan, 2},
  {:shuffle, 1},
  {:slice, 2},
  {:slice, 3},
  {:slide, 3},
  {:sort_by, 3},
  {:sort, 2},
  {:sort, 1},
  {:split_while, 2},
  {:split_with, 2},
  {:split, 2},
  {:sum_by, 2},
  {:sum, 1},
  {:take_every, 2},
  {:take_random, 2},
  {:take_while, 2},
  {:take, 2},
  {:to_list, 1},
  {:uniq_by, 2},
  {:uniq, 1},
  {:unzip, 1},
  {:with_index, 2},
  {:zip_reduce, 4},
  {:zip_reduce, 3},
  {:zip_with, 3},
  {:zip_with, 2},
  {:zip, 2},
  {:zip, 1}
]

# Extract documentation from Elixir's compiled docs
{:docs_v1, _, :elixir, _, _, _, functions} = Code.fetch_docs(Enum)

seeded_count = 0

Enum.each(enum_functions, fn {name, arity} ->
  # Find the documentation for this function
  doc_entry =
    Enum.find(functions, fn
      {{:function, ^name, ^arity}, _, _, _, _} -> true
      _ -> false
    end)

  {documentation, examples} =
    case doc_entry do
      {{:function, ^name, ^arity}, _line, _signature, doc_content, _metadata} ->
        doc_text =
          case doc_content do
            %{"en" => text} -> String.trim(text)
            _ -> "Documentation not available."
          end

        # Extract examples from documentation
        examples_text =
          if String.contains?(doc_text, "## Examples") do
            doc_text
            |> String.split("## Examples")
            |> List.last()
            |> String.trim()
          else
            "iex> Enum.#{name}(...)\n# Try this function yourself!"
          end

        {doc_text, examples_text}

      nil ->
        {"Documentation not available.", "iex> Enum.#{name}(...)\n# Try this function yourself!"}
    end

  %EnumFunction{}
  |> EnumFunction.changeset(%{
    name: to_string(name),
    arity: arity,
    documentation: documentation,
    examples: examples
  })
  |> Repo.insert!()

  seeded_count = seeded_count + 1
end)

IO.puts("✅ Successfully seeded #{length(enum_functions)} official Enum functions!")
