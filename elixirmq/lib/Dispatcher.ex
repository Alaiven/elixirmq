require Logger

defmodule Dispatcher do
  use GenServer

  def start_link({subs, cache} = state, opts \\ []) do
    GenServer.start_link(__MODULE__, {subs, cache})
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
  
  def handle_call({:sub, channel, process}, _from, {subs, cache}) do
    Subscriptions.subscribe(subs, channel, process)

    cache_key = "queue:" <> channel

    case Cache.get_list(cache, cache_key) do
      {:ok, messages} ->
	Enum.map(messages, fn m -> MessageWorker.send_message_no_encode(process, m) end)
	Cache.remove_list(cache, cache_key)
    end

    {:reply, :ok, {subs, cache}}
  end

  def handle_call({:unsub, channel, process}, _from, {subs, cache}) do
    Subscriptions.unsubscribe(subs, channel, process)
    {:reply, :ok, {subs, cache}}
  end
  
  def handle_call({:send, channel, message}, _from, {subs, cache}) do
    case Subscriptions.get(subs, channel) do
      nil ->
	case MessageParser.encode(message) do
	  {:ok, msg} ->
	    Logger.info "logged" <> msg
	    Cache.store_list(cache, "queue:" <> channel, msg)
	  {:error, cause} ->
	    Logger.error "Invalid JSON: " <> cause
	end
	{:reply, :empty, {subs, cache}}
      subscribers ->
	Enum.map(subscribers, fn s -> MessageWorker.send_message(s, message) end)
	{:reply, :ok, {subs, cache}}
    end
  end
 
end
