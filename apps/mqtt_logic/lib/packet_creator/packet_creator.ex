defmodule PacketCreator do
  use Bitwise
  import MqttLogic

  def create_packet(:connect, :clean, client_id) do
    # username, password, will retain, will qos msb, will qos lsb, will flag, clean session, reserved
    flags = [0, 0, 0, 0, 0, 0, 1, 0]
    flags_byte = PacketHandler.set_flags(flags)

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

    payload = PacketHandler.preffix_length([client_id])

    rem_length = RemLength.encode_rem_len([], byte_size(variable_header) + byte_size(payload))

    fixed_header = <<0x10>> <> :binary.list_to_bin(rem_length)

    fixed_header <> variable_header <> payload
  end

  def create_packet(:connack, connect_return_code) do
    fixed_header = <<0x20, 2>>
    variable_header = <<0, connect_return_code>>
    fixed_header <> variable_header
  end

  def create_packet(:subscribe, topics, packet_id) do
    # packet ID set to 0 for QoS0
    variable_header = <<packet_id::size(16)>>

    payload = PacketHandler.compose_topics(:subscribe, topics)

    rem_length = RemLength.encode_rem_len([], byte_size(variable_header) + byte_size(payload))

    fixed_header = <<0x82>> <> :binary.list_to_bin(rem_length)

    fixed_header <> variable_header <> payload
  end

  def create_packet(:suback, packet_id, return_codes) do
    # packet ID set to 0 for QoS0
    # IO.inspect(packet_id)
    # variable_header = <<packet_id::size(16)>>
    variable_header = packet_id
    # suppose that all the topoics have QoS0, so the success return code is 0 for each of them
    payload = :binary.list_to_bin(return_codes)

    rem_length = RemLength.encode_rem_len([], byte_size(variable_header) + byte_size(payload))

    fixed_header = <<0x90>> <> :binary.list_to_bin(rem_length)

    fixed_header <> variable_header <> payload
  end

  def create_packet(:unsubscribe, topics, packet_id) do
    # packet ID set to 0 for QoS0
    variable_header = <<packet_id::size(16)>>

    payload = PacketHandler.assemble_topics(:unsubscribe, topics)

    rem_length = RemLength.encode_rem_len([], byte_size(variable_header) + byte_size(payload))

    fixed_header = <<0xA2>> <> :binary.list_to_bin(rem_length)

    fixed_header <> variable_header <> payload
  end

  def create_packet(:unsuback, packet_id, return_codes) do
    fixed_header = <<0xB0, 2>>
    # packet ID set to 0 for QoS0
    variable_header = <<packet_id::size(16)>>

    fixed_header <> variable_header
  end

  def create_packet(:publish, topic, message, {dup_flag, qos_level, retain}) do
    # no packet id due to current QoS0 only
    variable_header = PacketHandler.preffix_length([topic])
    payload = message
    rem_length = RemLength.encode_rem_len([], byte_size(variable_header) + byte_size(payload))

    fixed_header =
      <<0x3::size(4), dup_flag::size(1), qos_level::size(2), retain::size(1)>> <>
        :binary.list_to_bin(rem_length)

    fixed_header <> variable_header <> payload
  end
end
