defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  test "create_user/1" do
    assert ExBanking.create_user(generate_random_username()) == :ok
  end

  test "deposit/3" do
    user = generate_random_username()
    ExBanking.create_user(user)
    assert {:ok, 100} == ExBanking.deposit(user, 100, "USD")
  end

  test "withdraw/3" do
    user = generate_random_username()
    ExBanking.create_user(user)
    assert {:ok, 100} == ExBanking.deposit(user, 100, "USD")
    assert {:ok, 50} == ExBanking.withdraw(user, 50, "USD")
  end

  test "get_balance/2" do
    user = generate_random_username()
    ExBanking.create_user(user)
    assert {:ok, 100} == ExBanking.deposit(user, 100, "USD")
    assert {:ok, 50} == ExBanking.withdraw(user, 50, "USD")
    assert {:ok, 50} == ExBanking.get_balance(user, "USD")
  end

  test "send/4" do
    from_user = generate_random_username()
    to_user = generate_random_username()
    ExBanking.create_user(from_user)
    ExBanking.create_user(to_user)
    assert {:ok, 100} == ExBanking.deposit(from_user, 100, "USD")
    assert {:ok, 0} == ExBanking.get_balance(to_user, "XZY")
    assert {:ok, 0} == ExBanking.get_balance(to_user, "USD")
    assert {:ok, 30, 70} == ExBanking.send(from_user, to_user, 70, "USD")

    assert {:ok, 70} == ExBanking.get_balance(to_user, "USD")

    assert {:ok, 30} == ExBanking.get_balance(from_user, "USD")
  end

  defp generate_random_username(size \\ 10) do
    for _ <- 1..size, into: "", do: <<Enum.random('0123456789abcdefghijklmnopqrstuwvyxz')>>
  end
end
