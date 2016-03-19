defmodule Mem.Worker do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    {:ok, nil}
  end

  def handle_cast({:insert, names, key, value, ttl}, state) do
    expire(names[:expiry_ets], key, ttl)
    insert(names[:data_ets], key, value)
    {:noreply, state}
  end

  def handle_cast({:expire, names, key, ttl}, state) do
    expire(names[:expiry_ets], key, ttl)
    {:noreply, state}
  end

  def handle_cast({:delete, names, key}, state) do
    delete(names[:expiry_ets], key)
    delete(names[:data_ets], key)
    {:noreply, state}
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
