defmodule MessageReceiver do
  @host 'project.microlab.club'
  @local 'localhost'

  def start(port) do
    opts = [:binary, active: true, packet: 0]
    {:ok, socket} = :gen_tcp.connect(@local, port, opts)
    socket
    # :ok = :gen_tcp.send(socket, "HELLO THERE")
    # :ok = :gen_tcp.close(socket)
  end
end
