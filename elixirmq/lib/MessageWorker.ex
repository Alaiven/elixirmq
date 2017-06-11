require Logger

defmodule MessageWorker do
  use GenServer

  def start_link({connection, dispatcher, cache} = state, opts \\ []) do
    {:ok, client} =  GenServer.start_link(__MODULE__, {connection, cache}, opts)
    Task.start_link(fn -> MessageWorker.recv({connection, client, dispatcher}) end)
    {:ok, client}
  end

  def send_message(pid, message) do
    case MessageParser.encode(message) do
      {:ok, msg} ->	
	GenServer.call(pid, {:send_message, msg})
      {:error, cause} ->
	Logger.error "Invalid JSON: " <> cause
    end
  end

  def send_message_no_encode(pid, message) do
    GenServer.call(pid, {:send_message, message})
  end

  def handle_call({:send_message, message}, _from, {connection, cache} = state) do
    msg_log = "message: " <> message
    Cache.log(cache, msg_log)
    Cache.incr(cache)

    message_size = byte_size(message)
    :gen_tcp.send(connection, <<message_size :: size(32)>> <> message)
    {:reply, :ok, state}
  end

  # server end

  def recv(state) do
    recv(state, "", "")
  end

  defp recv({connection, client, dispatcher} = state, channel, data_reminder) do
    case :gen_tcp.recv(connection, 0) do
      {:ok, data} ->
	handle_data(state, channel, data_reminder <> data)	
      {:error, :closed} ->
	case channel do
	  "" ->
	    :ok
	  ch ->
	    Logger.info "Unsub: " <> ch
	    Dispatcher.unsubscribe(dispatcher, channel, client)
	end
    end
  end

  defp handle_data(state, channel, data) do
    case extract_message(data) do
      {:msg_too_short, reminder} ->
	recv(state, channel, reminder)
      {:ok, message, reminder} ->
	channel = handle_message(state, channel, message)
	handle_data(state, channel, reminder)
    end
  end

  defp handle_message({_, client, dispatcher}, channel, message) do
    case MessageParser.parse(message) do
      {:subscribe, new_channel} ->
	IO.inspect(client)
	Logger.info "Sub: " <> new_channel
	Dispatcher.subscribe(dispatcher, new_channel, client)
	new_channel
      {:send, channel, message} ->
	Dispatcher.send_message(dispatcher, channel, message)
	channel
      {:error, error} ->
	Logger.info error <> " ORIGINAL: " <> message
	channel
    end
  end

  defp extract_message(data) do
    if byte_size(data) < 4 do
      {:msg_too_short, data}
    else
      <<size :: binary-size(4)>> <> data = data
      <<msg_size :: size(32)>> = size
    
      if msg_size > byte_size(data) do
	{:msg_too_short, size <> data}
      else
	<<message :: binary-size(msg_size)>> <> reminder = data
	{:ok, message, reminder}
      end   
    end
  end

  
end
