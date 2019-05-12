defmodule PacketHandler do
  use Bitwise

  # def sas() do
  #   topics = [{"sas1", 0}, {"sas2", 1}, {"sas3", 2}]
  #   socket = "SEEES"

  #   Enum.map_reduce(topics, [], fn {topic, qos}, acc ->
  #     qos =
  #       case :ets.lookup(:topics, topic) do
  #         [] ->
  #           :ets.insert(:topics, {topic, [socket]})
  #           qos

  #         [{topic, clients}] ->
  #           unless socket in clients do
  #             :ets.insert(:topics, {topic, clients ++ [socket]})
  #           end

  #           qos

  #         _ ->
  #           128
  #       end

  #     {{topic, qos}, acc ++ [qos]}
  #   end)
  # end

  def divide_packet(entire_packet, packet_without_type) do
    rem_length = RemLength.decode_rem_length(:binary.bin_to_list(packet_without_type))
    fixed_header_length = byte_size(entire_packet) - rem_length

    <<fixed_header::binary-size(fixed_header_length), variable_and_payload::binary>> =
      entire_packet

    {fixed_header, variable_and_payload}
  end

  def extract_connect_flags(flags_byte, flags_array \\ [], offset \\ 0)

  def extract_connect_flags(_flags_byte, flags_array, 8) do
    flags_array
  end

  def extract_connect_flags(flags_byte, flags_array, offset) do
    IO.inspect(flags_byte)
    extract_connect_flags(flags_byte >>> 1, [flags_byte &&& 1 | flags_array], offset + 1)
  end

  def assemble_topics(:unsubscribe, topics_arraym(payload \\ ""))

  def assemble_topics(:unsubscribe, [], payload) do
    payload
  end

  def assemble_topics(:unsubscribe, [{topic, requested_qos} | tail], payload) do
    assemble_topics(:unsubscribe, tail, payload <> <<byte_size(topic)::size(16)>> <> topic)
  end

  def compose_topics(:subscribe, topics_array, payload \\ "")

  def compose_topics(:subscribe, [], payload) do
    payload
  end

  def compose_topics(:subscribe, [{topic, requested_qos} | tail], payload) do
    compose_topics(
      :subscribe,
      tail,
      payload <> <<byte_size(topic)::size(16)>> <> topic <> <<requested_qos>>
    )
  end

  def extract_topics(payload, topics \\ [])

  def extract_topics("", topics) do
    topics
  end

  def store_topics(topics) do
    Enum.map_reduce(topics, [], fn {topic, qos}, acc ->
      qos =
        case :ets.lookup(:topics, topic) do
          [] ->
            :ets.insert(:topics, {topic, [socket]})
            qos

          [{topic, clients}] ->
            unless socket in clients do
              :ets.insert(:topics, {topic, clients ++ [socket]})
            end

            qos

          _ ->
            128
        end

      {{topic, qos}, acc ++ [qos]}
    end)
  end

  def extract_topics(payload, topics) do
    <<topic_length::binary-size(2), rest::binary>> = payload
    topic_length = :binary.decode_unsigned(topic_length)
    <<topic::binary-size(topic_length), requested_qos::binary-size(1), rest::bitstring>> = rest
    extract_topics(rest, topics ++ [{topic, requested_qos}])
  end

  def preffix_length(fields_array, payload \\ "")

  def preffix_length([], payload) do
    payload
  end

  def preffix_length([head | tail], payload) do
    preffix_length(tail, payload <> <<byte_size(head)::size(16)>> <> head)
  end

  def set_flags(flags_array, byte_offset \\ 7, byte \\ 0)

  def set_flags([], _, byte) do
    byte
  end

  def set_flags([flag_bit | tail], offset, byte) do
    set_flags(tail, offset - 1, byte ||| flag_bit <<< offset)
  end
end

# <<130, 23, 0, 0, 0, 4, 115, 97, 115, 49, 0, 0, 4, 115, 97, 115, 50, 0, 0, 4, 115, 97, 115, 51, 0>>
