defmodule MessageReceiverTest do
  use ExUnit.Case
  doctest MessageReceiver

  test "greets the world" do
    assert MessageReceiver.hello() == :world
  end
end
