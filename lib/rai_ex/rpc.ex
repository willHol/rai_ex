defmodule RaiEx.RPC do
  @moduledoc """
  This module provides macros for generating rpc-invoking functions.
  """
  
  @doc false
  defmacro __using__(_opts) do
    quote do
      import RaiEx.RPC

      @behaviour RaiEx.RPC
    end
  end

  @doc """
  A macro for defining parameters and their types inside an rpc block.
  """
  defmacro param(name, type, opts \\ []) do
    quote do
      Module.put_attribute(__MODULE__, @current_action,
                            {unquote(name), unquote(type)})

      Module.put_attribute(__MODULE__, :"#{@current_action}_opts", unquote(opts))
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

      opts = Module.get_attribute(__MODULE__, :"#{@current_action}_opts") || []

      Module.eval_quoted __ENV__, [
        RaiEx.RPC.__build_keyword_func__(@current_action, param_to_type_keywords, opts),
        RaiEx.RPC.__build_seq_func__(@current_action, param_to_type_keywords, opts)
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
  def __build_keyword_func__(action, list, opts) do
    quote do
      def unquote(action) (unquote(RaiEx.RPC.__named_args_from_keyword__(__MODULE__, list))) do
        RaiEx.Tools.Validator.validate_types!(unquote(list), unquote(RaiEx.RPC.__named_args_from_keyword__(__MODULE__, list)))

        unquote(RaiEx.RPC.__named_args_from_keyword__(__MODULE__, list))
        |> Enum.into(%{})
        |> Map.put(:action, unquote(action))
        |> Poison.encode!
        |> post_json_rpc(unquote(opts))
      end
    end
  end

  @doc false
  def __build_seq_func__(action, list, opts) do
    quote do
      def unquote(action) (unquote_splicing(RaiEx.RPC.__seq_args_from_keyword__(__MODULE__, list))) do
        RaiEx.Tools.Validator.validate_types!(unquote(list), unquote(RaiEx.RPC.__named_args_from_keyword__(__MODULE__, list)))

        unquote(RaiEx.RPC.__named_args_from_keyword__(__MODULE__, list))
        |> Enum.into(%{})
        |> Map.put(:action, unquote(action))
        |> Poison.encode!
        |> post_json_rpc(unquote(opts))
      end
    end
  end
end