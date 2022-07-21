defmodule Core.User do
  @moduledoc """
  User module documentation
  """
  @enforce_keys :username

  defstruct [:username, balance: []]

  def new(username) do
    %__MODULE__{username: username}
  end
end
