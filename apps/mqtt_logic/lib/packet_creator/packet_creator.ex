defmodule PacketCreator do
  use Bitwise

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

  def create_packet(type)

  def create_packet(:connect) do
    # user name, password, will retain, will qos msb, will qos lsb, will flag, clean session, reserved
    flags = [1, 1, 0, 0, 1, 1, 1, 0]
    flags_byte = set_flags(flags, byte_offset(), 0)

    variable_header =
      :binary.list_to_bin([
        protocol_name_length_msb(),
        protocol_name_length_lsb(),
        protocol_name(),
        protocol_level(),
        flags_byte,
        msg_keepalive_msb(),
        msg_keepalive_lsb()
      ])

    payload =
      :binary.list_to_bin(preffix_length(["willtopic", "willmessage", "johndoe", "secret"], []))

    rem_length = RemLength.encode_rem_len([], byte_size(variable_header) + byte_size(payload))

    fixed_header = <<0x10>> <> :binary.list_to_bin(rem_length)

    fixed_header <> variable_header <> payload
  end

  def preffix_length(fields_array, payload)

  def preffix_length([], payload) do
    payload
  end

  def preffix_length([head | tail], payload) do
    preffix_length(tail, payload ++ [byte_size(head), head])
  end

  def set_flags(flags_array, byte_offset, byte)

  def set_flags([], _, byte) do
    byte
  end

  def set_flags([flag_bit | tail], offset, byte) do
    set_flags(tail, offset - 1, byte ||| flag_bit <<< offset)
  end
end
