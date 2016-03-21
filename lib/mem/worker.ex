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

  def handle_call({:expire, names, key, time}, _from, state) do
    expire(names.ttl_ets, key, time)
    {:reply, :ok, state}
  end

  def handle_call({:delete, names, key}, _from, state) do
    delete(names.ttl_ets, key)
    delete(names.data_ets, key)
    {:reply, :ok, state}
  end

  def handle_call({:update_field, names, key, field, value}, _from, state) do
    :ets.lookup(names.data_ets, key)
    |> case do
      [] -> %{}
      [{_, v}] -> v
    end
    |> case do
      v when is_map(v) ->
         insert(names.data_ets, key, put_in(v, [field], value))
         {:reply, :ok, state}
      _                ->
         {:reply, :err, state}
    end
  end

  def handle_call({:increase, names, key, value}, _from, state) do
    :ets.lookup(names.data_ets, key)
    |> case do
      [] -> 0
      [{_, v}] -> v
    end
    |> case do
      v when is_integer(v) or is_float(v) ->
         insert(names.data_ets, key, v + value)
         {:reply, :ok, state}
      _                                   ->
         {:reply, :err, state}
    end
  end


  defp expire(tab, key, nil) do
    delete(tab, key)
  end

  defp expire(tab, key, time) when is_integer(time) do
    insert(tab, key, time)
  end


  defp insert(tab, key, value) do
    :ets.insert(tab, {key, value})
  end

  defp delete(tab, key) do
    :ets.delete(tab, key)
  end

end
