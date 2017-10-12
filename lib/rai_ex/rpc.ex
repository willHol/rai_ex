defmodule RPC do
  # Callback invoked by `use`.
  #
  # For now it returns a quoted expression that
  # imports the module itself into the user code.
  
  @doc false
  defmacro __using__(_opts) do
    quote do
      import RPC

      @behaviour RPC
    end
  end

  defmacro param(name, type) do
    quote do
      Module.put_attribute(__MODULE__, @current_action, {unquote(name), unquote(type)})
    end
  end

  @callback post_json_rpc(map, pos_integer, tuple) :: {:ok, map} | {:error, any}

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
    quote do
      Module.put_attribute(__MODULE__, :current_action, unquote(action))
      Module.register_attribute(__MODULE__, unquote(action), accumulate: true)

      unquote(definition)

      param_to_type_keywords = Module.get_attribute(__MODULE__, unquote(action)) |> Enum.reverse()

      Module.eval_quoted __ENV__, [
        RPC.__build_keyword_func__(@current_action, param_to_type_keywords),
        RPC.__build_seq_func__(@current_action, param_to_type_keywords)
      ]
    end
  end

  @doc false
  def __named_args_from_keyword__(context, keyword_list) do
    Enum.map(keyword_list, fn {arg_name, _type} ->
      {:"#{arg_name}", Macro.var(:"#{arg_name}", context)}
    end)
  end

  @doc false
  def __seq_args_from_keyword__(context, keyword_list) do
    Enum.map(keyword_list, fn {arg_name, _type} ->
      Macro.var(:"#{arg_name}", context)
    end)
  end

  @doc false
  def __build_keyword_func__(action, list) do
    quote do
      def unquote(action) (unquote(RPC.__named_args_from_keyword__(__MODULE__, list))) do
        Validator.validate_types(unquote(list), unquote(RPC.__named_args_from_keyword__(__MODULE__, list)))

        unquote(RPC.__named_args_from_keyword__(__MODULE__, list))
        |> Enum.into(%{})
        |> Map.put(:action, unquote(action))
        |> Poison.encode!
        |> post_json_rpc
      end
    end
  end

  @doc false
  def __build_seq_func__(action, list) do
    quote do
      def unquote(action) (unquote_splicing(RPC.__seq_args_from_keyword__(__MODULE__, list))) do
        Validator.validate_types(unquote(list), unquote(RPC.__named_args_from_keyword__(__MODULE__, list)))

        unquote(RPC.__named_args_from_keyword__(__MODULE__, list))
        |> Enum.into(%{})
        |> Map.put(:action, unquote(action))
        |> Poison.encode!
        |> post_json_rpc
      end
    end
  end
end