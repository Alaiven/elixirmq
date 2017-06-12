require Logger

defmodule Dispatcher do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def send_message(pid, channel, message) do
    GenServer.call(pid, {:send, channel, message})
  end

  def subscribe(pid, channel, process) do
    GenServer.call(pid, {:sub, channel, process})
  end

  def unsubscribe(pid, channel, process) do
    GenServer.call(pid, {:unsub, channel, process})
  end
  
  def handle_call({:sub, channel, process}, _from, state) do
    Subscriptions.subscribe(App.Subscriptions, channel, process)

    cache_key = "queue:" <> channel

    case Cache.get_list(App.Cache, cache_key) do
      {:ok, messages} ->
	Enum.map(messages, fn m -> MessageWorker.send_message_no_encode(process, m) end)
	Cache.remove_list(App.Cache, cache_key)
    end

    {:reply, :ok, state}
  end

  def handle_call({:unsub, channel, process}, _from, state) do
    Subscriptions.unsubscribe(App.Subscriptions, channel, process)
    {:reply, :ok, state}
  end
  
  def handle_call({:send, channel, message}, _from, state) do
    case Subscriptions.get(App.Subscriptions, channel) do
      nil ->
	case MessageParser.encode(message) do
	  {:ok, msg} ->
	    Logger.info "logged" <> msg
	    Cache.store_list(App.Cache, "queue:" <> channel, msg)
	  {:error, cause} ->
	    Logger.error "Invalid JSON: " <> cause
	end
	{:reply, :empty, state}
      subscribers ->
	Enum.map(subscribers, fn s -> MessageWorker.send_message(s, message) end)
	{:reply, :ok, state}
    end
  end
 
end
