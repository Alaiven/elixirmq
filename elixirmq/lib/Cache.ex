require Logger

defmodule Cache do
  use GenServer

  def new(redis_conn) do
    GenServer.start_link(__MODULE__, redis_conn)
  end

  def store_list(pid, key, value) do
    GenServer.call(pid, {:store_l, key, value})
  end

  def get_list(pid, key) do
    GenServer.call(pid, {:get_l, key})
  end

  def remove_list(pid, key) do
    GenServer.call(pid, {:rem_l, key})
  end

  def incr(pid) do
    GenServer.call(pid, {:incr})
  end

  def log(pid, value) do
    GenServer.call(pid, {:log, value})
  end

  defp counter() do
    ["INCR", "messages:count"]
  end

  def handle_call({:store_l, key, value}, _from, redis_conn) do
    case Redix.pipeline(redis_conn, [["RPUSH", key, value], counter()]) do
      {:ok, result} ->
	{:reply, {:ok, hd(result)}, redis_conn}
      {:error, cause} ->
	Logger.error "Refis error: " <> cause
	{:reply, {:error, cause}, redis_conn}
    end
  end

  def handle_call({:get_l, key}, _from, redis_conn) do
    case Redix.pipeline(redis_conn, [["LRANGE", key, "0", "-1"], counter()]) do
      {:ok, result} ->
	{:reply, {:ok, hd(result)}, redis_conn}
      {:error, cause} ->
	Logger.error "Refis error: " <> cause
	{:reply, {:error, cause}, redis_conn}
    end
  end

  def handle_call({:rem_l, key}, _from, redis_conn) do
    case Redix.pipeline(redis_conn, [["DEL", key], counter()]) do
      {:ok, result} ->
	{:reply, {:ok, hd(result)}, redis_conn}
      {:error, cause} ->
	Logger.error "Refis error: " <> cause
	{:reply, {:error, cause}, redis_conn}
    end
  end

  def handle_call({:log, value}, _from, redis_conn) do
    key = "log:" <> DateTime.to_iso8601(DateTime.utc_now())
    Redix.pipeline(redis_conn, [
	  ["SET", key, value],
	  ["EXPIRE", key, "2"]])
    {:reply, :ok, redis_conn}
  end

  def handle_call({:incr}, _from, redis_conn) do
    Redix.command(redis_conn, counter())
    {:reply, :ok, redis_conn}
  end
  
end
