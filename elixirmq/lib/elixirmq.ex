require Logger

defmodule Elixirmq do
  use Application

  def start(_type, _args) do
    Logger.info "ElixirMQ is starting..."
    Task.start(fn -> tcp_start(30001) end)
  end

  defp tcp_start(port) do
    Logger.info "Server started on port: " <> Integer.to_string(port)
    tcp_options = [:binary, packet: :raw, active: false, reuseaddr: true]

    {:ok, conn} = Redix.start_link(host: "localhost", port: 6379)

    {:ok, cache} = Cache.new(conn)
    {:ok, subs} = Subscriptions.new(cache)
    {:ok, dispatcher} = Dispatcher.new(subs, cache)
    {:ok, socket} = :gen_tcp.listen(port, tcp_options)
    
    listen(socket, dispatcher)
  end

  defp listen(socket, dispatcher) do
    {:ok, conn} = :gen_tcp.accept(socket)
    {:ok, _} = :inet.peername(conn)
    spawn(fn -> MessageWorker.recv(conn, dispatcher) end)
    listen(socket, dispatcher)
  end

  
end
