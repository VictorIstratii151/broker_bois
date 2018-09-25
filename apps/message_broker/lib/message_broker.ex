defmodule MessageBroker do
  require Logger

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting packets on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client_socket} = :gen_tcp.accept(socket)
    serve(client_socket)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    {:ok, packet} = :gen_tcp.recv(socket, 0)
    IO.inspect(packet)
    serve(socket)
  end
end
