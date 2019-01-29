defmodule MessageReceiver do
  @local 'localhost'

  # use GenServer
  require Logger

  @local 'localhost'

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
        IO.inspect("Inpsecting the packet:")
        IO.inspect(packet)

      {:error, :closed} ->
        Logger.info("Connection closed.")

      something ->
        IO.inspect(something)
    end

    loop(socket)
  end
end
