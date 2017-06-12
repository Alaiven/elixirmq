require Logger

defmodule Subscriptions do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
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

  def handle_call({:subscribe, channel, process}, _from, subs) do
    case Map.fetch(subs, channel) do
      {:ok, value} ->
    	{:reply, :ok, Map.put(subs, channel, [process | value])}
      :error ->
    	{:reply, :ok, Map.put(subs, channel, [process])}
    end
  end

  def handle_call({:unsubscribe, channel, process}, _from, subs) do
    case Map.fetch(subs, channel) do
      {:ok, value} ->
    	{:reply, :ok, Map.put(subs, channel, List.delete(value, process))}
      :error ->
    	{:reply, :ok, subs}
    end
  end

  def handle_call({:get, channel}, _from, subs) do
    {:reply, subs[channel], subs}
  end


end
