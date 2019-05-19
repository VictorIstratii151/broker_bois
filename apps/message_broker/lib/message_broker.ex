defmodule MessageBroker do
  use Bitwise
  require Logger

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: 0, active: false, reuseaddr: true])
    Agent.start_link(fn -> [] end, name: :connected_clients)
    Logger.info("Accepting packets on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client_socket} = :gen_tcp.accept(socket)
    Task.start_link(fn -> serve(client_socket) end)
    loop_acceptor(socket)
  end

  def remove_from_connected_clients(client) do
    Agent.update(:connected_clients, &List.delete(&1, client))
  end

  def get_connected_clients do
    Agent.get(:connected_clients, & &1)
  end

  def add_connected_clients(client) do
    Agent.update(:connected_clients, &(&1 ++ [client]))
  end

  defp serve(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, packet} ->
        <<packet_type::size(4), rem_packet_type::size(4), rest::binary>> = packet

        case packet_type do
          1 ->
            Logger.info("Incoming CONNECT packet:")

            {_fixed, variable_and_payload} = PacketHandler.divide_packet(packet, rest)

            <<_protocol_length::binary-size(2), "MQTT", _protocol_level::binary-size(1),
              _connect_flags::binary-size(1), _keep_alive::binary-size(2),
              payload::binary>> = variable_and_payload

            <<client_id_length::binary-size(2), rest_payload::binary>> = payload
            client_id_length = :binary.decode_unsigned(client_id_length)

            <<client_id::binary-size(client_id_length), _rest::binary>> = rest_payload

            # IO.puts("protocol name: MQTT\n client ID: #{client_id}\n")

            add_connected_clients(client_id)
            response = PacketCreator.create_packet(:connack, 0)

            # IO.puts("sending a response!")
            :gen_tcp.send(socket, response)

          8 ->
            Logger.info("Incoming SUBSCRIBE packet")

            {_fixed, variable_and_payload} = PacketHandler.divide_packet(packet, rest)

            <<packet_id::binary-size(2), payload::binary>> = variable_and_payload
            # IO.inspect(packet_id)

            topics = PacketHandler.extract_topics(payload)

            {topics, return_codes} = PacketHandler.store_topics(topics, socket)
            # IO.puts("Client subscribed to topics:")

            # Enum.map(topics, fn {topic, _qos} ->
            #   IO.inspect(topic)
            # end)

            response = PacketCreator.create_packet(:suback, packet_id, return_codes)
            :gen_tcp.send(socket, response)

          3 ->
            Logger.info("Incoming PUBLISH packet")

            <<dup_flag::size(1), qos_level::size(2), retain::size(1)>> =
              <<rem_packet_type::size(4)>>

            {_fixed, variable_and_payload} = PacketHandler.divide_packet(packet, rest)

            <<topic_length::binary-size(2), rest::binary>> = variable_and_payload
            topic_length = :binary.decode_unsigned(topic_length)
            <<topic::binary-size(topic_length), payload::binary>> = rest

            subscriptions = :ets.lookup(:topics, topic)

            response =
              PacketCreator.create_packet(:publish, topic, payload, {dup_flag, qos_level, retain})

            unless length(subscriptions) == 0 do
              [{topic_name, client_list}] = subscriptions

              Enum.map(client_list, fn client ->
                :gen_tcp.send(client, response)
              end)
            end

          unmatched ->
            IO.inspect("oops")
            # IO.inspect(packet)
            # IO.inspect(unmatched)
        end

        serve(socket)

      # :gen_tcp.send(socket, "HELLO THERE BOIS")

      {:error, :enotconn} ->
        :gen_tcp.close(socket)

      {:error, :closed} ->
        Logger.info("Connection closed.")

      something ->
        IO.inspect("oops2")
        # Logger.info(something)
    end
  end

  def check_cache() do
    :ets.lookup(:topics, "123")
  end
end
