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


  @doc """
  A macro for generating rpc calling functions with validations.

      rpc :account_remove do
        param "wallet", :string
        param "account", :string
      end

  Transforms to a single function which takes arguments `wallet` and `account` in the *declared order*.
  Additionally this function performs **type checking** on the arguments, e.g. If the first argument
  `wallet` does not pass the `:string` type check, an `ArgumentError` will be raised.
  """
  defmacro rpc(action, do: definition) when is_atom(action) do
    params_list = param_list(definition)
    params_list_quoted = params_list |> Macro.escape

    types_list_quoted = type_list(definition) |> Macro.escape

    args = create_args(__MODULE__, Enum.count(params_list))

    quote do
      def unquote(action)(unquote_splicing(args)) do
        Validator.validate_types(unquote(args), unquote(types_list_quoted))

        Enum.zip(unquote(params_list_quoted), unquote(args))
        |> Enum.into(%{})
        |> Map.put("action", unquote(action))
        |> Poison.encode!
        |> post_json_rpc
      end
    end
  end

  # Gathers a list of params, in the defined order.
  #
  # Example:
  #
  # rpc :account_remove do
  #   param "wallet", :string
  #   param "account", :string
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

  # Gathers a list of types, in the defined order.
  #
  # Example:
  #
  # rpc :account_remove do
  #   param "wallet", :string
  #   param "account", :string
  # end
  #
  # Yields:
  #
  # [:string, :string]
  #
  defp type_list(definition) do
    {_, list} = Macro.prewalk(definition, [],
      fn pre, list ->
        case pre do
          {:param, _line, [_param, type]} ->
            {pre, [type | list]}
          _ ->
            {pre, list}
        end
      end)

    list |> Enum.reverse
  end

  # Creates a dynamic arguments list, where each argument
  # is a variable instead of a constant.
  defp create_args(_, 0), do: []
  defp create_args(fn_mdl, arg_cnt), do: Enum.map(1..arg_cnt, &(Macro.var (:"arg#{&1}"), fn_mdl))
end
