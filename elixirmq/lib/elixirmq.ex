require Logger

defmodule Elixirmq do
  use Application

  def start(_type, _args) do
    Logger.info "ElixirMQ is starting..."
    App.Supervisor.start_link
    Task.start(fn -> tcp_start(30001) end)
  end

  defp tcp_start(port) do
    Logger.info "Server started on port: " <> Integer.to_string(port)
    tcp_options = [:binary, packet: :raw, active: false, reuseaddr: true]
    
    {:ok, socket} = :gen_tcp.listen(port, tcp_options)
    
    listen(socket)
  end

  defp listen(socket) do
    {:ok, conn} = :gen_tcp.accept(socket)
    
    Task.start_link(fn -> MessageWorker.start_link conn end)
    
    listen(socket)
  end

  
end
