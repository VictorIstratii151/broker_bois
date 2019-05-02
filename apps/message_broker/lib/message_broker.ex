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
        <<packet_type::binary-size(1), rest::binary>> = packet

        case packet_type do
          <<0x10>> ->
            IO.inspect("Incoming CONNECT packet")

            rem_length = RemLength.decode_rem_length(:binary.bin_to_list(rest))
            fixed_header_length = byte_size(packet) - rem_length

            <<_fixed::binary-size(fixed_header_length), variable_and_payload::binary>> = packet

            <<_protocol_length::binary-size(2), "MQTT", _protocol_level::binary-size(1),
              _connect_flags::binary-size(1), _keep_alive::binary-size(2),
              payload::binary>> = variable_and_payload

            <<client_id_length::binary-size(2), rest_payload::binary>> = payload
            client_id_length = :binary.decode_unsigned(client_id_length)

            <<client_id::binary-size(client_id_length), _rest::binary>> = rest_payload
            IO.inspect(client_id)

            response = PacketCreator.create_packet(:connack, 0)
            :gen_tcp.send(socket, response)

          <<0x82>> ->
            IO.inspect("Incoming SUBSCRIBE packet")

            rem_length = RemLength.decode_rem_length(:binary.bin_to_list(rest))
            fixed_header_length = byte_size(packet) - rem_length

            <<_fixed::binary-size(fixed_header_length), variable_and_payload::binary>> = packet

            <<packet_id::binary-size(2), topic_length::binary-size(2), rest::binary>> =
              variable_and_payload

            topic_length = :binary.decode_unsigned(topic_length)
            <<topic::binary-size(topic_length), max_qos::binary-size(1)>> = rest

            IO.inspect(packet_id)
            IO.inspect(topic)
            IO.inspect(max_qos)

            response = PacketCreator.create_packet(:suback, :binary.decode_unsigned(packet_id))
            :gen_tcp.send(socket, response)

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
