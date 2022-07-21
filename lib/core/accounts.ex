defmodule Core.Accounts do
  @moduledoc """
  Documentation for Core.Accounts
  """
  use GenServer
  alias Core.User

  def init(v), do: {:ok, v}

  def start_link(username) do
    #    {user} = username

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

  def get(username), do: GenServer.call(via(username), :get)

  def deposit(username, amount, currency) do
    cond do
      !is_binary(username) || !is_binary(currency) || !is_number(amount) || amount <= 0 ->
        {:error, :wrong_arguments}

      !user_exists?(username) ->
        {:error, :user_does_not_exist}

      true ->
        deposit = %{username: username, amount: amount, currency: currency}
        GenServer.cast(via(username), {:deposit, deposit})
        get_balance(username, currency)
    end
  end

  def withdraw(username, amount, currency) do
    cond do
      !is_binary(username) || !is_binary(currency) || !is_number(amount) || amount <= 0 ->
        {:error, :wrong_arguments}

      !user_exists?(username) ->
        {:error, :user_does_not_exist}

      true ->
        {:ok, total_available} = get_balance(username, currency)

        if total_available >= amount do
          withdraw = %{username: username, amount: amount, currency: currency}
          GenServer.cast(via(username), {:withdraw, withdraw})
          get_balance(username, currency)
        else
          {:error, :not_enough_money}
        end
    end
  end

  def get_balance(username, currency) do
    cond do
      !is_binary(username) || !is_binary(currency) ->
        {:error, :wrong_arguments}

      !user_exists?(username) ->
        {:error, :user_does_not_exist}

      true ->
        user = get(username)

        balance =
          Enum.reduce(user.balance, 0, fn transaction, acc ->
            if transaction.currency == currency do
              transaction.amount + acc
            else
              acc
            end
          end)

        {:ok, balance}
    end
  end

  def send(from_user, to_user, amount, currency) do
    cond do
      !is_binary(from_user) || !is_binary(to_user) || !is_binary(currency) ||
        !is_number(amount) || amount <= 0 ->
        {:error, :wrong_arguments}

      !user_exists?(from_user) ->
        {:error, :sender_does_not_exist}

      !user_exists?(to_user) ->
        {:error, :receiver_does_not_exist}

      true ->
        {:ok, total_sender_available} = get_balance(from_user, currency)

        if total_sender_available >= amount do
          withdraw = %{username: from_user, amount: amount, currency: currency}
          deposit = %{username: to_user, amount: amount, currency: currency}

          GenServer.cast(via(from_user), {:withdraw, withdraw})
          GenServer.cast(via(to_user), {:deposit, deposit})

          {:ok, from_user_balance} = get_balance(from_user, currency)
          {:ok, to_user_balance} = get_balance(to_user, currency)
          {:ok, from_user_balance, to_user_balance}
        else
          {:error, :not_enough_money}
        end
    end
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

  def user_exists?(username) do
    pid = Registry.lookup(:accounts, username)

    if pid != [], do: true, else: false
  end

  def handle_deposit(state, deposit) do
    %{state | balance: [%{amount: deposit.amount, currency: deposit.currency} | state.balance]}
  end

  def handle_withdraw(state, deposit) do
    %{state | balance: [%{amount: -deposit.amount, currency: deposit.currency} | state.balance]}
  end

  def via(username), do: {:via, Registry, {:accounts, username}}

  def child_spec(__MODULE__, username) do
    %{
      id: {:via, Registry, {username}},
      start: {Core.Accounts, :start_link, [username]}
    }
  end
end
