defmodule MessageReceiver do
  @local 'localhost'

  # use GenServer
  require Logger

  def tst() do
    socket = start(1337)
    packet = PacketCreator.create_packet(:connect, :clean, "boi1")
    IO.inspect(packet)
    send_msg(socket, packet)
  end

  def start(port) do
    opts = [:binary, packet: 0, active: false, reuseaddr: true]
    {:ok, socket} = :gen_tcp.connect(@local, port, opts)
    Task.start_link(fn -> loop(socket) end)
    socket
  end

  def send_msg(socket, data) do
    :gen_tcp.send(socket, data)
  end

  def subscribe(socket, topic) do
    data = "subscribe" <> "," <> topic
    send_msg(socket, data)
  end

  def publish(socket, topic, payload) do
    data = "publish" <> "," <> topic <> "," <> payload
    send_msg(socket, data)
  end

  def loop(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, packet} ->
        IO.inspect(packet)
        <<packet_type::binary-size(1), rest::binary>> = packet

        case packet_type do
          <<0x20>> ->
            IO.inspect("Incoming CONNACK packet")

            rem_length = RemLength.decode_rem_length(:binary.bin_to_list(rest))
            fixed_header_length = byte_size(packet) - rem_length

            <<_fixed::binary-size(fixed_header_length), _variable::binary>> = packet

            response = PacketCreator.create_packet(:subscribe, "sooos1", 0)
            send_msg(socket, response)

          <<0x90>> ->
            IO.inspect("Incoming SUBACK packet")
            rem_length = RemLength.decode_rem_length(:binary.bin_to_list(rest))
            fixed_header_length = byte_size(packet) - rem_length

            <<_fixed::binary-size(fixed_header_length), variable_and_payload::binary>> = packet

            <<packet_id::binary-size(2), return_code::binary>> = variable_and_payload

            IO.inspect(packet_id)
            IO.inspect(return_code)

          _ ->
            IO.inspect("sas")
        end

        loop(socket)

      {:error, :enotconn} ->
        :gen_tcp.close(socket)

      {:error, :closed} ->
        IO.inspect("Connection closed.")

      something ->
        IO.inspect(something)
        loop(socket)
    end
  end
end
