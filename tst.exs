
# Elixir v1.0
defmodule Rules do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
      @rules []
    end
  end

  # Store each rules in the @rules attribute so we can
  # compile them all at once later
  defmacro rule(condition, do: block) do
    condition = Macro.escape(condition)
    block     = Macro.escape(block)
    quote do
      @rules [{unquote(condition), unquote(block)}|@rules]
    end
  end

  defmacro __before_compile__(env) do
    rules = Module.get_attribute(env.module, :rules)
    arg   = quote do: arg

    # Compile each rule to a ->.
    #
    # Later we will inject those clauses into a cond.
    rules = Enum.flat_map rules, fn {condition, block} ->
      condition = add_arg(condition, arg)
      quote do: (unquote(condition) -> unquote(block))
    end

    quote do
      def run_rules(arg) do
        # Make the argument available in the block as the "number" var.
        # This is usually seen as bad practice but here it goes as an example.
        var!(number) = arg
        cond do: unquote(rules)
      end
    end
  end

  # A rule is writen as "foo and bar" but each item in the rule
  # implicitly receives an argument. So we go into each node,
  # taking into account "and/or" operators and pipe the arg as
  # the first argument.
  defp add_arg({op, meta, [left, right]}, arg) when op in [:and, :or] do
    {op, meta, [add_arg(left, arg), add_arg(right, arg)]}
  end

  defp add_arg(other, arg) do
    Macro.pipe(arg, other, 0)
  end
end

defmodule Sample do
  use Rules

  rule is_one do
    IO.puts "A"
  end

  rule is_more_than_one and is_less_than_ten do
    IO.puts "B"
  end

  rule is_more_than(10) and is_less_than(99) do
    IO.puts "C"
  end

  rule is_more_than(100) do
    IO.puts "D: #{number}"
  end

  defp is_one(x), do: x == 1
  defp is_more_than_one(x), do: x > 1
  defp is_less_than_ten(x), do: x < 10
  defp is_more_than(x, y), do: x > y
  defp is_less_than(x, y), do: x < y
end

Sample.run_rules(1)
Sample.run_rules(5)
Sample.run_rules(50)
Sample.run_rules(150)