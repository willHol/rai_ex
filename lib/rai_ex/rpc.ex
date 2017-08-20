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

	defmacro rpc(action, do: definition) when is_atom(action) do
		map = gen_map(definition)
		map_macro = Macro.escape(map)
		args = create_args(__MODULE__, Enum.count(map))

		quote do
			function_name = unquote(action)

			def unquote(action)(unquote_splicing(args)) when true do
				Enum.zip(Map.keys(unquote(map_macro)), unquote(args))
				|> Enum.into(%{})
				|> Map.put("action", unquote(action))
				|> Poison.encode!
    		|> post_json_rpc
			end
		end
	end

	defp gen_map(definition) do
			{_, map} = Macro.traverse(definition, %{},
				fn pre, map -> 
					case pre do
						{:param, _line, [key, value]} ->
							{pre, Map.put(map, key, value)}
						_ ->
							{pre, map}
					end
				end,
				# Identity function
				fn post, map -> {post, map} end
			)
			map
	end

	defp create_args(_, 0),
	  do: []
	defp create_args(fn_mdl, arg_cnt),
	  do: Enum.map(1..arg_cnt, &(Macro.var (:"arg#{&1}"), fn_mdl))
end