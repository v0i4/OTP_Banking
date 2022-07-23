defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
    API interface for banking operations:

  ex:
    ExBanking.create_user("some_user") \n
    ExBanking.deposit("some_user", 100, "USD")\n
    ExBanking.withdraw("some_user", 100, "BRL")\n
    ExBanking.get_balance("some_user", "USD")\n
    ExBanking.send("from_user", "to_user", "100", "BRL")\n
  """

  @doc """
  create_user/1.

  Creates a new user with a given `username` 

  Returns `:ok`

  ## Examples


      iex> ExBanking.create_user("user_example")
      :ok

  """
  def create_user(username) do
    case DynamicSupervisor.start_child(:users, {Boundary.Server, username}) do
      {_, :ok} -> :ok
      err -> err
    end
  end

  @doc """
  deposit/3

  Deposits the `amount` of `currency` to the `user`

  Returns `{:ok, new_user_balance}`

  ## Example

      iex> ExBanking.create_user("test")
      iex> ExBanking.deposit("test", 100, "USD")
      iex> {:ok, 100}
  """
  defdelegate deposit(user, amount, currency), to: Core.Accounts

  @doc """
  withdraw/3

  Withdraws the `amount` of `currency` from the `user`

  Returns `{:ok, new_user_balance}`

  ## Example

    iex> ExBanking.create_user("test")
    iex> ExBanking.deposit("test", 100, "JPY")
    iex> ExBanking.withdraw("test", 50, "JPY")
    {:ok, 50}
  """
  defdelegate withdraw(user, amount, currency), to: Core.Accounts

  @doc """
  get_balance/2

  Get the `user` balance for the given `currency`

  Returns {:ok, user_balance}

  ## Example

    iex> ExBanking.create_user("test")
    iex> ExBanking.get_balance("test", "ANY")
    {:ok, 0}
    
  """
  defdelegate get_balance(user, currency), to: Core.Accounts

  @doc """
  send/4

  Sends the `amount` of `currency` `from_user` to `to_user`

  Returns {:ok, from_user_balance, to_user_balance}

  ## Example

    iex> ExBanking.create_user("from_user")
    iex> ExBanking.create_user("to_user")
    iex> ExBanking.deposit("from_user", 100, "BRL")
    iex> ExBanking.send("from_user", "to_user", 60, "BRL")
    iex> {:ok, 40, 60}


  """
  defdelegate send(from_user, to_user, amount, currency), to: Core.Accounts
end
