require Logger

defmodule MessageWorker do

  def recv(connection, dispatcher) do
    recv(connection, dispatcher, "", "")
  end

  defp recv(connection, dispatcher, channel, data_reminder) do
    case :gen_tcp.recv(connection, 0) do
      {:ok, data} ->
	handle_data(connection, dispatcher, channel, data_reminder <> data)	
      {:error, :closed} ->
	case channel do
	  "" ->
	    :ok
	  ch ->
	    Logger.info "Unsub: " <> ch
	    Dispatcher.unsubscribe(dispatcher, channel, connection)
	end
    end
  end

  defp handle_data(connection, dispatcher, channel, data) do
    case extract_message(data) do
      {:msg_too_short, reminder} ->
	recv(connection, dispatcher, channel, reminder)
      {:ok, message, reminder} ->
	channel = handle_message(message, dispatcher, connection, channel)
	handle_data(connection, dispatcher, channel, reminder)
    end
  end

  defp extract_message(data) do
    if byte_size(data) < 4 do
      {:msg_too_short, data}
    else
      <<size :: binary-size(4)>> <> data = data
      <<msg_size :: size(32)>> = size
    
      Logger.info "Size:" <> Integer.to_string(msg_size)
    
      if msg_size > byte_size(data) do
	{:msg_too_short, size <> data}
      else
	<<message :: binary-size(msg_size)>> <> reminder = data
	{:ok, message, reminder}
      end   
    end
  end

  defp handle_message(message, dispatcher, connection, channel) do
    case MessageParser.parse(message) do
      {:subscribe, new_channel} ->
	Logger.info "Sub: " <> new_channel
	Dispatcher.subscribe(dispatcher, new_channel, connection)
	new_channel
      {:send, channel, message} ->
	Dispatcher.send_message(dispatcher, channel, message)
	channel
      {:error, error} ->
	Logger.info error <> " ORIGINAL: " <> message
	channel
    end
  end

  def snd(connection, message) do
    case MessageParser.encode(message) do
      {:ok, msg} ->
	message_size = byte_size(msg)
	:gen_tcp.send(connection, <<message_size :: size(32)>> <> msg)
      {:error, msg} ->
	Logger.info "Invalid JSON to send: " <> msg
    end
   
  end
  
end
