defmodule Validator do
	@type_checkers %{
		:string => {Kernel, :is_binary},
		:number => {Kernel, :is_number},
		:integer => {Kernel, :is_integer}
	}

	def validate_types(arg_values, types) do
		Enum.zip(arg_values, types)
		|> Enum.each(fn {arg, type} ->
			{mod, fun} = @type_checkers[type]

			if not apply(mod, fun, [arg]) do
				raise ArgumentError, message: "Invalid argument."
			end
		end)
	end
end