defmodule Mem.Worker do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    {:ok, nil}
  end

  def handle_call({:insert, names, key, value, ttl}, _from, state) do
    expire(names.ttl_ets, key, ttl)
    insert(names.data_ets, key, value)
    {:reply, :ok, state}
  end

  def handle_call({:expire, names, key, ttl}, _from, state) do
    expire(names.ttl_ets, key, ttl)
    {:reply, :ok, state}
  end

  def handle_call({:delete, names, key}, _from, state) do
    delete(names.ttl_ets, key)
    delete(names.data_ets, key)
    {:reply, :ok, state}
  end


  defp expire(tab, key, nil) do
    delete(tab, key)
  end

  defp expire(tab, key, ttl) when is_integer(ttl) do
    ttl = Mem.Utils.now + ttl
    insert(tab, key, ttl)
  end


  defp insert(tab, key, value) do
    :ets.insert(tab, {key, value})
  end

  defp delete(tab, key) do
    :ets.delete(tab, key)
  end

end
