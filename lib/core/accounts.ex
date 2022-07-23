defmodule Core.Accounts do
  @moduledoc """
  Documentation for Core.Accounts
  """
  alias Boundary.Server

  def get(username), do: GenServer.call(Server.via(username), :get)

  def deposit(username, amount, currency) do
    cond do
      !is_binary(username) || !is_binary(currency) || !is_number(amount) || amount <= 0 ->
        {:error, :wrong_arguments}

      !user_exists?(username) ->
        {:error, :user_does_not_exist}

      true ->
        deposit = %{username: username, amount: amount, currency: currency}

        if Server.check_overload(username) do
          {:error, :too_many_requests_to_user}
        else
          GenServer.cast(Server.via(username), {:deposit, deposit})
          get_balance(username, currency)
        end
    end
  end

  # with expected args
  def withdraw(username, amount, currency)
      when is_binary(username) and is_binary(currency) and is_number(amount) and amount > 0 do
    if user_exists?(username) do
      case get_balance(username, currency) do
        {:ok, total_available} ->
          if total_available >= amount do
            withdraw = %{username: username, amount: amount, currency: currency}

            if Server.check_overload(username) do
              {:error, :too_many_requests_to_user}
            else
              GenServer.cast(Server.via(username), {:withdraw, withdraw})
              get_balance(username, currency)
            end
          else
            {:error, :not_enough_money}
          end

        error ->
          error
      end
    else
      {:error, :user_does_not_exist}
    end
  end

  def withdraw(_username, _amount, _currency) do
    {:error, :wrong_arguments}
  end

  def get_balance(username, currency) do
    cond do
      !is_binary(username) || !is_binary(currency) ->
        {:error, :wrong_arguments}

      !user_exists?(username) ->
        {:error, :user_does_not_exist}

      true ->
        if Server.check_overload(username) do
          {:error, :too_many_requests_to_user}
        else
          user = get(username)

          balance =
            Enum.reduce(user.balance, 0, fn transaction, acc ->
              if transaction.currency == currency do
                transaction.amount + acc
              else
                acc
              end
            end)

          format_number(balance)
        end
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
        case get_balance(from_user, currency) do
          {:ok, total_sender_available} ->
            if total_sender_available >= amount do
              withdraw = %{username: from_user, amount: amount, currency: currency}
              deposit = %{username: to_user, amount: amount, currency: currency}

              cond do
                Server.check_overload(from_user) ->
                  {:error, :too_many_requests_to_sender}

                Server.check_overload(to_user) ->
                  {:error, :too_many_requests_to_receiver}

                true ->
                  GenServer.cast(Server.via(from_user), {:withdraw, withdraw})
                  GenServer.cast(Server.via(to_user), {:deposit, deposit})

                  with {:ok, from_user_balance} <- get_balance(from_user, currency),
                       {:ok, to_user_balance} <- get_balance(to_user, currency) do
                    {:ok, from_user_balance, to_user_balance}
                  else
                    error -> error
                  end
              end
            else
              {:error, :not_enough_money}
            end

          error ->
            error
        end
    end
  end

  defp user_exists?(username) do
    pid = Registry.lookup(:accounts, username)

    if pid != [], do: true, else: false
  end

  defp format_number(balance) do
    case is_float(balance) do
      true ->
        balance = :erlang.float_to_binary(balance, decimals: 2) |> :erlang.binary_to_float()
        {:ok, balance}

      false ->
        {:ok, balance}
    end
  end
end
