defmodule App.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:ok, conn} = Redix.start_link(host: "localhost", port: 6379)

    children = [
      worker(Cache, [conn, [name: App.Cache]]),
      worker(Subscriptions, [[name: App.Subscriptions]]),
      worker(Dispatcher, [[name: App.Dispatcher]])
    ]

    supervise(children, strategy: :one_for_one)
  end

  
end
