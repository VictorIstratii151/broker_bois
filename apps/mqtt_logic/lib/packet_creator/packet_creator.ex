defmodule PacketCreator do
  use Bitwise

  def create_packet(fields, type)

  def create_packet({fixed_header, variable_header, payload}, :connect) do
    {packet_type, remaining_length} = fixed_header

    {length_msb, length_lsb, protocol_name, level, flags, keep_alive_msb, keep_alive_lsb} =
      variable_header
  end

  def set_flags(flags_array, offset, byte)

  def set_flags([], offset, byte) do
    byte
  end

  def set_flags([head | tail], offset, byte) do
    IO.inspect(byte)
    set_flags(tail, offset - 1, byte ||| head <<< offset)
  end

  def create_packet() do
    packet_type = 0x10
    remaining_length = 0xF
    length_msb = 0
    length_lsb = 4
    protocol_name = "MQTT"

    level = 4

    flags = 0xCE

    keep_alive_msb = 0
    keep_alive_lsb = 0xA

    payload = "HELLO"

    <<packet_type, remaining_length, length_msb, length_lsb>> <>
      protocol_name <> <<level, flags, keep_alive_msb, keep_alive_lsb>> <> payload
  end
end
