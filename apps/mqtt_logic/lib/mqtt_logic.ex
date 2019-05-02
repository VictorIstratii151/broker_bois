defmodule MqttLogic do
  @offset 7
  @protocol_name_length_msb 0
  @protocol_name_length_lsb 4
  @protocol_name "MQTT"
  @protocol_level 4
  @msg_keepalive_msb 0
  @msg_keepalive_lsb 10
  def byte_offset, do: @offset
  def protocol_name_length_msb, do: @protocol_name_length_msb
  def protocol_name_length_lsb, do: @protocol_name_length_lsb
  def protocol_name, do: @protocol_name
  def protocol_level, do: @protocol_level
  def msg_keepalive_msb, do: @msg_keepalive_msb
  def msg_keepalive_lsb, do: @msg_keepalive_lsb
end
