defmodule MqttLogicTest do
  use ExUnit.Case
  doctest MqttLogic

  test "greets the world" do
    assert MqttLogic.hello() == :world
  end
end
