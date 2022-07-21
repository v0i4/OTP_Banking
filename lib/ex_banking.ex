defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  @doc """
  create_user/1.

  ## Examples

      iex> ExBanking.create_user("some_user")
      :ok

  """
  def create_user(username) do
    DynamicSupervisor.start_child(:users, {Core.Accounts, username})
  end

  @doc """
  deposit/3

  ## Example

      iex> ExBanking.create_user("test")
      iex> ExBanking.deposit("test", 100, "USD")
      iex> {:ok, 100}
  """
  defdelegate deposit(user, amount, currency), to: Core.Accounts

  @doc """
  withdraw/3

  ## Example

    iex> ExBanking.create_user("test")
    iex> ExBanking.deposit("test", 100, "JPY")
    iex> ExBanking.withdraw("test", 50, "JPY")
    {:ok, 50}
  """
  defdelegate withdraw(user, amount, currency), to: Core.Accounts

  @doc """
  get_balance/2

  ## Example

    iex> ExBanking.create_user("test")
    iex> ExBanking.get_balance("test", "ANY")
    {:ok, 0}
    
  """
  defdelegate get_balance(user, currency), to: Core.Accounts

  @doc """
  send/4

  ## Example

    iex> ExBanking.create_user("from_user")
    iex> ExBanking.create_user("to_user")
    iex> ExBanking.deposit("from_user", 100, "BRL")
    iex> ExBanking.send("from_user", "to_user", 60, "BRL")
    iex> {:ok, 40, 60}


  """
  defdelegate send(from_user, to_user, amount, currency), to: Core.Accounts
end
