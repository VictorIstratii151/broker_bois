defmodule MessageBroker do
  use Bitwise
  require Logger

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: 0, active: false, reuseaddr: true])

    Logger.info("Accepting packets on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client_socket} = :gen_tcp.accept(socket)
    Task.start_link(fn -> serve(client_socket) end)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, packet} ->
        <<packet_type::size(4), rem_packet_type::size(4), rest::binary>> = packet

        case packet_type do
          1 ->
            IO.inspect("Incoming CONNECT packet")

            {_fixed, variable_and_payload} = PacketHandler.divide_packet(packet, rest)

            <<_protocol_length::binary-size(2), "MQTT", _protocol_level::binary-size(1),
              _connect_flags::binary-size(1), _keep_alive::binary-size(2),
              payload::binary>> = variable_and_payload

            <<client_id_length::binary-size(2), rest_payload::binary>> = payload
            client_id_length = :binary.decode_unsigned(client_id_length)

            <<client_id::binary-size(client_id_length), _rest::binary>> = rest_payload

            response = PacketCreator.create_packet(:connack, 0)
            :gen_tcp.send(socket, response)

          8 ->
            IO.inspect("Incoming SUBSCRIBE packet")

            {_fixed, variable_and_payload} = PacketHandler.divide_packet(packet, rest)

            <<packet_id::binary-size(2), payload::binary>> = variable_and_payload

            topics = PacketHandler.extract_topics(payload)

            {topics, return_codes} = PacketHandler.store_topics(topics)

            # IO.inspect(return_codes)

            response = PacketCreator.create_packet(:suback, packet_id, return_codes)

          3 ->
            IO.inspect("Incoming PUBLISH packet")

            <<_dup_flag::size(1), _qos_level::size(2), _retain::size(1)>> =
              <<rem_packet_type::size(4)>>

            {_fixed, variable_and_payload} = PacketHandler.divide_packet(packet, rest)

            <<topic_length::binary-size(2), rest::binary>> = variable_and_payload
            topic_length = :binary.decode_unsigned(topic_length)
            <<topic::binary-size(topic_length), payload::binary>> = rest

            IO.inspect(topic)
            IO.inspect(payload)

          _ ->
            IO.inspect("sas")
        end

        serve(socket)

      # :gen_tcp.send(socket, "HELLO THERE BOIS")

      {:error, :enotconn} ->
        :gen_tcp.close(socket)

      {:error, :closed} ->
        Logger.info("Connection closed.")

      something ->
        Logger.info(something)
    end
  end

  def check_cache() do
    :ets.lookup(:topics, "123")
  end
end
