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
        <<packet_type::size(4), rem_packet_type::size(4), rest::binary>> = packet

        case packet_type do
          2 ->
            IO.inspect("Incoming CONNACK packet")

            {_fixed, variable_and_payload} = PacketHandler.divide_packet(packet, rest)

            response =
              PacketCreator.create_packet(:subscribe, [{"sas1", 0}, {"sas2", 0}, {"sas3", 0}], 0)

            send_msg(socket, response)

          9 ->
            IO.inspect("Incoming SUBACK packet")

            {_fixed, variable_and_payload} = PacketHandler.divide_packet(packet, rest)

            <<packet_id::binary-size(2), return_code::binary>> = variable_and_payload

            msg = PacketCreator.create_packet(:publish, "sooos1", "hahah mda)", {0, 0, 0})
            send_msg(socket, msg)

          _ ->
            IO.inspect("sas")
        end

        loop(socket)

      {:error, :enotconn} ->
        :gen_tcp.close(socket)

      {:error, :closed} ->
        Logger.info("Connection closed.")

      something ->
        IO.inspect(something)
        loop(socket)
    end
  end
end
