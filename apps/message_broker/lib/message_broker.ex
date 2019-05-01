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
              connect_flags::binary-size(1), _keep_alive::binary-size(2),
              payload::binary>> = variable_and_payload

            <<client_id_length::binary-size(2), rest_payload::binary>> = payload
            client_id_length = :binary.decode_unsigned(client_id_length)

            <<client_id::binary-size(client_id_length), _rest::binary>> = rest_payload
            IO.inspect(client_id)

          _ ->
            IO.inspect("sas")
        end

        :gen_tcp.send(socket, "HELLO THERE BOIS")

      {:error, :closed} ->
        Logger.info("Connection closed.")

      something ->
        Logger.info(something)
    end

    serve(socket)
  end

  def check_cache() do
    :ets.lookup(:topics, "123")
  end
end
