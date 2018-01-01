defmodule RaiEx.CircuitBreaker do
  @moduledoc false

  use GenServer
  import HTTPoison, only: [request: 5]

  alias HTTPoison.Response
  alias HTTPoison.Error

  @max_error 3
  @period 1000

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, 0}
  end

  def post(url, body, headers \\ [], opts \\ []) do
    GenServer.call(__MODULE__, {:post, url, body, headers, opts})
  end

  # ==== GENSERVER CALLBACKS ==== #

  def handle_call({:post, url, body, headers, opts}, _from, error_count) do
    if blown?(error_count) do
      {:reply, :blown, error_count}
    else
      case make_request(:post, url, body, headers, opts) do
        {:ok, body} ->
          {:reply, {:ok, body}, error_count}
        {:error, reason} ->
          send(self(), :add_error)
          {:reply, {:error, reason}, error_count}
      end
    end
  end

  def handle_info(:add_error, error_count) do
    _ = schedule_error_remove(@period)
    {:noreply, error_count + 1}
  end

  def handle_info(:remove_error, error_count) do
    {:noreply, error_count - 1}
  end

  # ==== PRIVATE FUNCTIONS ==== #

  defp make_request(method, url, body, headers, opts) do
    case request(:post, url, body, headers, opts) do
      {:ok, %Response{status_code: 200, body: body}} -> {:ok, body}
      {:ok, %Response{status_code: code}} -> {:error, code}
      {:error, %Error{reason: reason}} -> {:error, reason}
    end
  end

  defp blown?(error_count), do: error_count >= @max_error

  defp schedule_error_remove(period) do
    Process.send_after(self(), :remove_error, period)
  end
end