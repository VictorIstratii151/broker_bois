defmodule MessageBroker do
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
        IO.inspect("Inpsecting the packet:")
        IO.inspect(packet)

      {:error, :closed} ->
        Logger.info("Connection closed.")

      something ->
        IO.inspect(something)
    end

    # {:ok, packet} = :gen_tcp.recv(socket, 0)
    # IO.inspect(packet)
    serve(socket)
  end
end
