require JSON

defmodule MessageParser do

  def encode(message) do
    JSON.encode(message)
  end

  def parse(message) do
    try do
      case JSON.decode(message) do
	{:ok, value} ->
	  case parse_map(value) do
	    {:error, msg} ->
	      {:error, "Error in json: " <> msg}
	    x -> x
	  end
	{:error, msg} ->
	  {:error, "Error during decoding a message: " <> msg}
      end
    rescue
      ArgumentError -> {:error, "Invalid JSON"}
    end
  end

  defp parse_map(map) do
    case Map.fetch(map, "command") do
      {:ok, command} ->
	parse_command(command, map)
      :error ->
	{:error, "No command key!"}
    end
  end

  defp parse_command(command, map) do
    case command do
      "subscribe" ->
	case Map.fetch(map, "channel") do
	  {:ok, channel} ->
	    {:subscribe, channel}
	  :error ->
	    {:error, "Subscribe - no channel key!"}
	end
      "send" ->
	case Map.fetch(map, "message") do
	  {:ok, message} ->
	    case Map.fetch(map, "channel") do
	      {:ok, channel} ->
		{:send, channel, message}
	      :error ->
		{:error, "Subscribe - no channel key!"}
	    end
	  :error ->
	    {:error, "Send - no message key!"}
	end
      _ ->
	{:error, "Invalid command: " <> command}	
    end

  end

end
