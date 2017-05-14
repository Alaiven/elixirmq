require Logger

defmodule Dispatcher do
  use GenServer

  def new(subs, cache) do
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
	Enum.map(messages, fn m -> send_message_direct(process, m, cache)  end)
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
	Enum.map(subscribers, fn s -> encode_send_message(s, message, cache)  end)
	{:reply, :ok, {subs, cache}}
    end
  end

  defp encode_send_message(sub, message, cache) do
    case MessageParser.encode(message) do
      {:ok, msg} ->	
	send_message_direct(sub, msg, cache)
      {:error, cause} ->
	Logger.error "Invalid JSON: " <> cause
    end
  end
    
  defp send_message_direct(sub, msg, cache) do
    spawn(fn -> MessageWorker.send_message(sub, msg) end)
    msg_log = "message: " <> msg
    Cache.log(cache, msg_log)
    Cache.incr(cache)
  end
  
end
