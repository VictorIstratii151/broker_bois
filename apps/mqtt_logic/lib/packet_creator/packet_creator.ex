defmodule PacketCreator do
  use Bitwise
  import MqttLogic

  # def create_packet(type)

  def create_packet(:connect, :clean) do
    # username, password, will retain, will qos msb, will qos lsb, will flag, clean session, reserved
    flags = [0, 0, 0, 0, 0, 0, 1, 0]
    flags_byte = set_flags(flags)

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

    payload = preffix_length(["boi1"], "")

    rem_length = RemLength.encode_rem_len([], byte_size(variable_header) + byte_size(payload))

    fixed_header = <<0x10>> <> :binary.list_to_bin(rem_length)

    fixed_header <> variable_header <> payload
  end

  def create_packet(:connack, connect_return_code) do
    fixed_header = <<0x20, 2>>
    variable_header = <<0, connect_return_code>>
    fixed_header <> variable_header
  end

  def preffix_length(fields_array, payload)

  def preffix_length([], payload) do
    payload
  end

  def preffix_length([head | tail], payload) do
    preffix_length(tail, payload <> <<byte_size(head)::16>> <> head)
  end

  def set_flags(flags_array, byte_offset \\ 7, byte \\ 0)

  def set_flags([], _, byte) do
    byte
  end

  def set_flags([flag_bit | tail], offset, byte) do
    set_flags(tail, offset - 1, byte ||| flag_bit <<< offset)
  end
end
