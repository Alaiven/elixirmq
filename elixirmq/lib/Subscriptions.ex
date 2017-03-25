defmodule Subscriptions do
  use GenServer

  def new do
    GenServer.start_link(__MODULE__, %{})
  end

  def subscribe(pid, channel, process) do
    GenServer.call(pid, {:subscribe, channel, process})
  end

  def unsubscribe(pid, channel, process) do
    GenServer.call(pid, {:unsubscribe, channel, process})
  end

  def get(pid, channel) do
    GenServer.call(pid, {:get, channel})
  end

  def init(value) do
    {:ok, value}
  end

  def handle_call({:subscribe, channel, process}, _from, subscriptions) do
    case Map.fetch(subscriptions, channel) do
      {:ok, value} ->
	{:reply, :ok, Map.put(subscriptions, channel, [process | value])}
      :error ->
	{:reply, :ok, Map.put(subscriptions, channel, [process])}
    end
  end

  def handle_call({:unsubscribe, channel, process}, _from, subscriptions) do
    case Map.fetch(subscriptions, channel) do
      {:ok, value} ->
	{:reply, :ok, Map.put(subscriptions, channel, List.delete(value, process))}
      :error ->
	{:reply, :ok, subscriptions}
    end
  end

  def handle_call({:get, channel}, _from, subscriptions) do
    {:reply, subscriptions[channel], subscriptions}
  end


end
