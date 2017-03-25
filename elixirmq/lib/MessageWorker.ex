require Logger

defmodule MessageWorker do

  def recv(connection, dispatcher) do
    case :gen_tcp.recv(connection, 0) do
      {:ok, data} ->
	handle_message(data, dispatcher, connection)
	recv(connection, dispatcher)
      {:error, :closed} ->
	:ok
    end
  end

  defp handle_message(message, dispatcher, connection) do
    case MessageParser.parse(message) do
      {:subscribe, channel} ->
	Logger.info "Sub: " <> channel
	Dispatcher.subscribe(dispatcher, channel, connection)
      {:send, channel, message} ->
	Dispatcher.send_message(dispatcher, channel, message)
      {:error, error} ->
	Logger.info error <> " ORIGINAL: " <> message
    end
  end

  def snd(connection, message) do
    case MessageParser.encode(message) do
      {:ok, msg} ->
	:gen_tcp.send(connection, msg)
      {:error, msg} ->
	Logger.info "Invalid JSON to send: " <> msg
    end
   
  end
  
end
