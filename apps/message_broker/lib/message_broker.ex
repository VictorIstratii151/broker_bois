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
        case String.split(packet, ",") do
          ["subscribe", topic] ->
            IO.inspect(packet)

            case :ets.lookup(:topics, topic) do
              [] ->
                :ets.insert(:topics, {topic, [socket]})

              [{topic, clients}] ->
                :ets.insert(:topics, {topic, clients ++ [socket]})
            end

          ["publish", topic, data] ->
            case :ets.lookup(:topics, topic) do
              [{_, clients}] ->
                Enum.map(clients, fn client ->
                  :gen_tcp.send(client, data)
                end)

              [] ->
                :ok
            end

          _ ->
            IO.inspect("sas")
        end

        :gen_tcp.send(socket, "HELLO THERE BOIS")

      {:error, :closed} ->
        Logger.info("Connection closed.")

      something ->
        Logger.info(something)
    end

    # {:ok, packet} = :gen_tcp.recv(socket, 0)
    # IO.inspect(packet)
    serve(socket)
  end

  def check_cache() do
    :ets.lookup(:topics, "123")
  end
end
