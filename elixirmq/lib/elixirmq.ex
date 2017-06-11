require Logger

defmodule Elixirmq do
  import Supervisor.Spec
  use Application

  def start(_type, _args) do
    Logger.info "ElixirMQ is starting..."
    Task.start(fn -> tcp_start(30001) end)
  end

  defp tcp_start(port) do
    Logger.info "Server started on port: " <> Integer.to_string(port)
    tcp_options = [:binary, packet: :raw, active: false, reuseaddr: true]

    {:ok, conn} = Redix.start_link(host: "localhost", port: 6379)

    children = [
      worker(Cache, conn, [name: MyCache]),
      worker(Subscriptions, MyCache, [name: MySubscriptions]),
      worker(Dispatcher, {MySubscriptions, MyCache}, [name: MyDispatcher])
    ]
    
    {:ok, supervisor} = Supervisor.start_link(children, strategy: :one_for_one)
    
    {:ok, socket} = :gen_tcp.listen(port, tcp_options)
    
    listen(socket, supervisor)
  end

  defp listen(socket, supervisor) do
    {:ok, conn} = :gen_tcp.accept(socket)
    Supervisor.start_child(supervisor, worker(MessageWorker, {conn, MyDispatcher, MyCache}))
    listen(socket, supervisor)
  end

  
end
