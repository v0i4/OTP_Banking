defmodule Core.AccountsTest do
  use ExUnit.Case
  alias Boundary.Server
  alias Core.Accounts
  doctest Core.Accounts

  describe "start_link/1" do
    test "start_link with success" do
      assert :ok == Server.start_link(generate_random_username())
    end

    test "start_link already running for the user" do
      Server.start_link("test")
      assert {:error, :user_already_exists} == Server.start_link("test")
    end

    test "start_link with wrong arguments" do
      assert {:error, :wrong_arguments} == Server.start_link(123)
    end
  end

  describe "deposit/3" do
    test "successful deposit" do
      user = generate_random_username()
      assert :ok == Server.start_link(user)
      assert {:ok, 50} == Accounts.deposit(user, 50, "USD")
    end

    test "deposit with wrong arguments" do
      user = generate_random_username()
      assert :ok == Server.start_link(user)
      assert {:error, :wrong_arguments} == Accounts.deposit(user, "50", "USD")
      assert {:error, :wrong_arguments} == Accounts.deposit(user, 50, 123)
    end

    test "deposit to inexistent user" do
      user = generate_random_username()
      assert {:error, :user_does_not_exist} == Accounts.deposit(user, 100, "BRL")
    end

    test "deposit to a user with too many requests" do
      user = generate_random_username()
      Server.start_link(user)

      resp =
        1..3000
        |> Enum.map(fn _ -> Task.async(fn -> Accounts.deposit(user, 1, "BRL") end) end)
        |> Enum.map(fn x -> Task.await(x) end)
        |> Enum.reduce([], fn item, acc ->
          {_status, msg} = item
          [msg | acc]
        end)

      assert Enum.any?(resp, fn msg -> msg == :too_many_requests_to_user end)
    end
  end

  describe "withdraw/3" do
    test "successful withdraw" do
      user = generate_random_username()
      assert :ok == Server.start_link(user)
      assert {:ok, 100} == Accounts.deposit(user, 100, "JPY")
      assert {:ok, 50} == Accounts.withdraw(user, 50, "JPY")
    end

    test "withdraw with wrong arguments" do
      user = generate_random_username()
      assert :ok == Server.start_link(user)
      assert {:ok, 100} == Accounts.deposit(user, 100, "JPY")
      assert {:error, :wrong_arguments} == Accounts.withdraw(user, "50", "JPY")
      assert {:error, :wrong_arguments} == Accounts.withdraw(user, 50, 123)
    end

    test "withdraw with inexistent user" do
      user = generate_random_username()
      assert {:error, :user_does_not_exist} == Accounts.withdraw(user, 100, "BRL")
    end

    test "withdraw with insufficient money" do
      user = generate_random_username()
      assert :ok == Server.start_link(user)
      assert {:ok, 100} == Accounts.deposit(user, 100, "JPY")
      assert {:error, :not_enough_money} == Accounts.withdraw(user, 101, "JPY")
    end

    test "withdraw with too many requested user" do
      user = generate_random_username()
      Server.start_link(user)
      assert {:ok, 3000} = Accounts.deposit(user, 3000, "USD")

      resp =
        1..3000
        |> Enum.map(fn _ -> Task.async(fn -> Accounts.withdraw(user, 1, "BRL") end) end)
        |> Enum.map(fn x -> Task.await(x) end)
        |> Enum.reduce([], fn item, acc ->
          {_status, msg} = item
          [msg | acc]
        end)

      assert Enum.any?(resp, fn msg -> msg == :too_many_requests_to_user end)
    end
  end

  describe "balance/2" do
    test "getting balance with success" do
      user = generate_random_username()
      assert :ok == Server.start_link(user)
      assert {:ok, 0} == Accounts.get_balance(user, "USD")
      assert {:ok, 0} == Accounts.get_balance(user, "EUR")
      assert {:ok, 100} == Accounts.deposit(user, 100, "JPY")
      assert {:ok, 200} == Accounts.deposit(user, 200, "BRL")
      assert {:ok, 400.10} == Accounts.deposit(user, 200.10000000000000022323213213, "BRL")
      assert {:ok, 600.22} == Accounts.deposit(user, 200.123123, "BRL")
      assert {:ok, 600.22} == Accounts.get_balance(user, "BRL")
    end

    test "balance with wrong arguments" do
      user = generate_random_username()
      assert :ok == Server.start_link(user)
      assert {:error, :wrong_arguments} == Accounts.get_balance(123, "BRL")
      assert {:error, :wrong_arguments} == Accounts.get_balance(user, 123)
    end

    test "get balance of an inexistent user" do
      user = generate_random_username()
      assert {:error, :user_does_not_exist} == Accounts.get_balance(user, "BRL")
    end

    test "get balance of too many requested user" do
      user = generate_random_username()
      Server.start_link(user)
      assert {:ok, 3000} = Accounts.deposit(user, 3000, "USD")

      resp =
        1..3000
        |> Enum.map(fn _ -> Task.async(fn -> Accounts.get_balance(user, "BRL") end) end)
        |> Enum.map(fn x -> Task.await(x) end)
        |> Enum.reduce([], fn item, acc ->
          {_status, msg} = item
          [msg | acc]
        end)

      assert Enum.any?(resp, fn msg -> msg == :too_many_requests_to_user end)
    end
  end

  describe "send/4" do
    test "successful send" do
      from_user = generate_random_username()
      to_user = generate_random_username()

      assert :ok == Server.start_link(from_user)
      assert :ok == Server.start_link(to_user)

      assert {:ok, 500} == Accounts.deposit(from_user, 500, "BRL")
      assert {:ok, 250, 250} == Accounts.send(from_user, to_user, 250, "BRL")
      assert {:ok, 0, 500} == Accounts.send(from_user, to_user, 250, "BRL")
    end

    test "send with wrong arguments" do
      assert {:error, :wrong_arguments} == Accounts.send(213, 123, 123, "BRL")
      assert {:error, :wrong_arguments} == Accounts.send(213, 123, 123, 123)
    end

    test "send with not enough money" do
      from_user = generate_random_username()
      to_user = generate_random_username()

      assert :ok == Server.start_link(from_user)
      assert :ok == Server.start_link(to_user)

      assert {:ok, 500} == Accounts.deposit(from_user, 500, "BRL")
      assert {:error, :not_enough_money} == Accounts.send(from_user, to_user, 501, "BRL")
    end

    test "send from inexistent user" do
      from_user = generate_random_username()
      to_user = generate_random_username()

      assert :ok == Server.start_link(to_user)

      assert {:error, :user_does_not_exist} == Accounts.deposit(from_user, 500, "BRL")
      assert {:error, :sender_does_not_exist} == Accounts.send(from_user, to_user, 500, "BRL")
    end

    test "send to inexistent user" do
      from_user = generate_random_username()
      to_user = generate_random_username()

      assert :ok == Server.start_link(from_user)

      assert {:error, :user_does_not_exist} == Accounts.deposit(to_user, 500, "BRL")
      assert {:error, :receiver_does_not_exist} == Accounts.send(from_user, to_user, 200, "BRL")
    end

    test "send from too many requested user" do
      from_user = generate_random_username()
      to_user = generate_random_username()
      Server.start_link(from_user)
      Server.start_link(to_user)

      assert {:ok, 10000} = Accounts.deposit(from_user, 10000, "USD")

      resp =
        1..3000
        |> Enum.map(fn _ -> Task.async(fn -> Accounts.send(from_user, to_user, 1, "USD") end) end)
        |> Enum.map(fn _ -> Task.async(fn -> Accounts.get_balance(from_user, "USD") end) end)
        |> Enum.map(fn x -> Task.await(x) end)
        |> Enum.reduce([], fn item, acc ->
          {_status, msg} = item
          [msg | acc]
        end)

      assert Enum.any?(resp, fn msg -> msg == :too_many_requests_to_user end)
    end

    test "send to too many requested user" do
      from_user = generate_random_username()
      to_user = generate_random_username()
      Server.start_link(from_user)
      Server.start_link(to_user)

      assert {:ok, 10000} = Accounts.deposit(from_user, 10000, "USD")

      resp =
        1..3000
        |> Enum.map(fn _ -> Task.async(fn -> Accounts.send(from_user, to_user, 1, "BRL") end) end)
        |> Enum.map(fn x -> Task.await(x) end)
        |> Enum.reduce([], fn item, acc ->
          {_status, msg} = item
          [msg | acc]
        end)

      assert Enum.any?(resp, fn msg -> msg == :too_many_requests_to_user end)
    end
  end

  test "child spec" do
    user = "testABC"

    assert Server.child_spec(user) == %{
             id: {:via, Registry, {"testABC"}},
             start: {Server, :start_link, ["testABC"]}
           }
  end

  defp generate_random_username(size \\ 10) do
    for _ <- 1..size, into: "", do: <<Enum.random('0123456789abcdefghijklmnopqrstuwvyxz')>>
  end
end
