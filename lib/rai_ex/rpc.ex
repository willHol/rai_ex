defmodule RPC do
	# Callback invoked by `use`.
	 #
	 # For now it returns a quoted expression that
	 # imports the module itself into the user code.
	 @doc false
	defmacro __using__(_opts) do
	  quote do
	    import RPC
	  end
	end

	@type_checkers %{
		:string => :is_binary,
		:integer => :is_integer,
		:number => :is_number
	}

	defmacro rpc(action, do: definition) when is_atom(action) do
		params_to_types = param_to_type(definition)
		params_to_types_quoted = Macro.escape(params_to_types)

		params_list_quoted = param_list(definition) |> Macro.escape

		args = create_args(__MODULE__, Enum.count(params_to_types))

		quote do
			function_name = unquote(action)

			def unquote(action)(unquote_splicing(args)) when unquote(param_function_checks(args, )) do
				Enum.zip(unquote(params_list_quoted), unquote(args))
				|> Enum.into(%{})
				|> Map.put("action", unquote(action))
				|> Poison.encode!
    		|> post_json_rpc
			end
		end
	end

	defp check_types(arg_values, param_names, params_to_types) do
		params_to_values = Enum.zip(param_names, arg_values) |> Enum.into(%{})

		params_to_values
		|> Enum.map(fn {param, value} -> 
			{value, @type_checkers[params_to_types[param]]}
		end)
		|> chain_type_conditions
	end

	# `conditions` is a list of tuples:
	#
	# [{A, B}, {C, D}]
	def chain_equality_conditions(conditions) do
		case conditions do
			[{a, b} | rest] when rest != [] ->
				quote do: unquote(a) == unquote(b) and unquote(chain_equality_conditions(rest))
			[{a, b} | _rest] ->
				quote do: unquote(a) == unquote(b)
		end
	end

	# `conditions` is a list of tuples:
	# 
	# [{valueA, is_?}, {valueB, is_?}]
	def chain_type_conditions(conditions) do
		case conditions do
			[{value, fun} | rest] when rest != [] ->
				quote do: unquote(fun)(unquote(value)) and unquote(chain_equality_conditions(rest))
			[{value, fun} | _rest] ->
				quote do: unquote(fun)(unquote(value))
		end
	end

	# [is_number(1), is_binary("hello")]
	def chain_conditions(conditions) do
		case conditions do
			[condition | rest] when rest != [] ->
				quote do: unquote(condition) and unquote(chain_conditions(rest))
			[condition | _rest] ->
				quote do: unquote(condition)
		end
	end

	def param_function_checks do
		
	end

	# Gathers the params and types into a map of the form:
	#
	# %{
	#	<param1> => <type1>
	#   <param2> => <type2>
	# }
	defp param_to_type(definition) do
		{_tree, map} = Macro.prewalk(definition, %{},
			fn pre, map -> 
				case pre do
				{:param, _line, [param, type]} ->
					{pre, Map.put(map, param, type)}
				_ ->
					{pre, map}
			end
		end)

		map
	end

	# Gathers a list of params, in the defined order.
	#
	# Example:
	#
	# rpc :account_remove do
    # 	param "wallet", :string
    # 	param "account", :string
    # end
    #
    # Yields:
    #
    # ["wallet", "account"]
	#
	defp param_list(definition) do
		{_, list} = Macro.prewalk(definition, [],
			fn pre, list -> 
				case pre do
					{:param, _line, [param, _type]} ->
						{pre, [param | list]}
					_ ->
						{pre, list}
				end
			end)

		list |> Enum.reverse
	end

	# Creates a dynamic arguments list, where each argument
	# is a variable instead of a constant.
	defp create_args(_, 0),
	  do: []
	defp create_args(fn_mdl, arg_cnt),
	  do: Enum.map(1..arg_cnt, &(Macro.var (:"arg#{&1}"), fn_mdl))
end