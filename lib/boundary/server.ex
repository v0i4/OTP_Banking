defmodule Boundary.Server do
  @moduledoc false
  alias Core.User

  use GenServer

  def init(v), do: {:ok, v}

  def start_link(username) do
    if is_binary(username) do
      case GenServer.start_link(__MODULE__, User.new(username), name: via(username)) do
        {:ok, _pid} ->
          :ok

        {:error, {:already_started, _pid}} ->
          {:error, :user_already_exists}
      end
    else
      {:error, :wrong_arguments}
    end
  end

  def via(username), do: {:via, Registry, {:accounts, username}}

  def child_spec(username) do
    %{
      id: {:via, Registry, {username}},
      start: {__MODULE__, :start_link, [username]}
    }
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:deposit, deposit}, state) do
    {:noreply, handle_deposit(state, deposit)}
  end

  def handle_cast({:withdraw, withdraw}, state) do
    {:noreply, handle_withdraw(state, withdraw)}
  end

  defp handle_deposit(state, deposit) do
    %{state | balance: [%{amount: deposit.amount, currency: deposit.currency} | state.balance]}
  end

  defp handle_withdraw(state, deposit) do
    %{state | balance: [%{amount: -deposit.amount, currency: deposit.currency} | state.balance]}
  end

  defp get_pid_by_name(process_name) do
    name = Registry.lookup(:accounts, process_name)
    {pid, _} = name |> hd()
    pid
  end

  defp too_many_request?(pid, max_queue_length \\ 10) do
    if Process.alive?(pid) do
      {:message_queue_len, queue_length} = Process.info(pid, :message_queue_len)
      if queue_length > max_queue_length, do: true, else: false
    else
      true
    end
  end

  def check_overload(username) do
    get_pid_by_name(username)
    |> too_many_request?
  end
end
