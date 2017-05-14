require Logger

defmodule Subscriptions do
  use GenServer

  def new(cache) do
    GenServer.start_link(__MODULE__, {%{}, cache})
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

  def handle_call({:subscribe, channel, process}, _from, {subs, cache}) do
    case Map.fetch(subs, channel) do
      {:ok, value} ->
    	{:reply, :ok, {Map.put(subs, channel, [process | value]), cache}}
      :error ->
    	{:reply, :ok, {Map.put(subs, channel, [process]), cache}}
    end
    # case Cache.store_set(cache, "subs:" <> channel, process) do
    #   {:ok, _} ->
    # 	{:reply, :ok, {subs, cache}}
    #   {:error, cause} ->
    # 	Logger.error "Cahce error: " <> cause
    # 	{:reply, :error, {subs, cache}}
    # end
  end

  def handle_call({:unsubscribe, channel, process}, _from, {subs, cache}) do
    case Map.fetch(subs, channel) do
      {:ok, value} ->
    	{:reply, :ok, {Map.put(subs, channel, List.delete(value, process)), cache}}
      :error ->
    	{:reply, :ok, {subs, cache}}
    end
    # case Cache.remove_set(cache, "subs:" <> channel, process) do
    #  {:ok, _} ->
    # 	{:reply, :ok, {subs, cache}}
    #   {:error, cause} ->
    # 	Logger.error "Cahce error: " <> cause
    # 	{:reply, :error, {subs, cache}}
    # end
  end

  def handle_call({:get, channel}, _from, {subs, cache}) do
    {:reply, subs[channel], {subs, cache}}
    # case Cache.get_set(cache, "subs:" <> channel) do
    #  {:ok, value} ->
    # 	{:reply, value, {subs, cache}}
    #   {:error, cause} ->
    # 	Logger.error "Cahce error: " <> cause
    # 	{:reply, :error, {subs, cache}}
    # end
  end


end
