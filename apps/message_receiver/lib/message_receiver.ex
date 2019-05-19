defmodule MessageReceiver do
  @local 'localhost'

  # use GenServer
  require Logger

  def tst() do
    socket = start(1337)
    packet = PacketCreator.create_packet(:connect, :clean, "boi1")
    IO.inspect("Sending a CONNECT packet")
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
        <<packet_type::size(4), rem_packet_type::size(4), rest::binary>> = packet

        case packet_type do
          2 ->
            Logger.info("Incoming CONNACK packet")

            {_fixed, _variable_and_payload} = PacketHandler.divide_packet(packet, rest)

          9 ->
            Logger.info("Incoming SUBACK packet")

            {_fixed, variable_and_payload} = PacketHandler.divide_packet(packet, rest)

            <<_packet_id::binary-size(2), _return_codes::binary>> = variable_and_payload

          3 ->
            Logger.info("Incoming PUBLISH packet")

            <<_dup_flag::size(1), _qos_level::size(2), _retain::size(1)>> =
              <<rem_packet_type::size(4)>>

            {_fixed, variable_and_payload} = PacketHandler.divide_packet(packet, rest)

            <<topic_length::binary-size(2), rest::binary>> = variable_and_payload
            topic_length = :binary.decode_unsigned(topic_length)
            <<topic::binary-size(topic_length), payload::binary>> = rest

            Logger.info("Analyzing incoming message:")
            Logger.info("Topic: #{topic}")
            Logger.info("Data: #{payload}")

          unmatched ->
            Logger.info(unmatched)
            IO.inspect("oops")
        end

        loop(socket)

      {:error, :enotconn} ->
        :gen_tcp.close(socket)

      {:error, :closed} ->
        Logger.info("Connection closed.")

      something ->
        Logger.info("Unknown error")
        IO.inspect(something)
        loop(socket)
    end
  end
end
