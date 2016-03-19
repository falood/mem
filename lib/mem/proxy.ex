defmodule Mem.Proxy do
  use GenServer

  def get(names, hash, key) do
    ( with {:ok, ttl} <- lookup(names[:expiry_ets], key),
           now = Mem.Utils.now,
           true <- now > ttl,
      do: :expire
    ) |> case do
      :expire ->
        take_worker(names, hash) |> GenServer.call({:delete, names, key})
        nil
      _       ->
        lookup(names[:data_ets], key) |> elem(1)
    end
  end

  def ttl(names, hash, key) do
    now = Mem.Utils.now
    ttl = lookup(names[:expiry_ets], key) |> elem(1)
    cond do
      is_nil(ttl) ->
        nil
      now > ttl   ->
        take_worker(names, hash) |> GenServer.call({:delete, names, key})
        nil
      true        ->
        ttl - now
    end
  end

  def set(names, hash, key, value, ttl)
  when is_nil(ttl) or is_integer(ttl) do
    take_worker(names, hash) |> GenServer.call({:insert, names, key, value, ttl})
    :ok
  end

  def expire(names, hash, key, ttl)
  when is_nil(ttl) or is_integer(ttl) do
    case get(names, hash, key) do
      nil -> nil
      _   ->
        take_worker(names, hash) |> GenServer.call({:expire, names, key, ttl})
        :ok
    end
  end

  def del(names, hash, key) do
    take_worker(names, hash) |> GenServer.call({:delete, names, key})
    :ok
  end

  def start_link(names) do
    GenServer.start_link(__MODULE__, names, name: names[:proxy_name])
  end

  def init(names) do
    {:ok, names}
  end

  def handle_call({:create_worker, hash}, _from, names) do
    result =
      case try_take_worker(names, hash) do
        nil ->
          pid = create_worker(names[:worker_sup_name])
          :ets.insert(names[:proxy_ets], {hash, pid})
          pid
        pid -> pid
      end
    {:reply, result, names}
  end

  defp take_worker(names, hash) do
    try_take_worker(names, hash) || GenServer.call(names[:proxy_name], {:create_worker, hash})
  end

  defp try_take_worker(names, hash) do
    ( with {:ok, pid} when is_pid(pid) <- lookup(names[:proxy_ets], hash),
           true <- Process.alive?(pid),
      do: {:take, pid}
    ) |> case do
      {:take, pid} -> pid
       _           -> nil
    end
  end

  defp lookup(tab, key) do
    case :ets.lookup(tab, key) do
      [{^key, value}] -> {:ok, value}
      []              -> {:err, nil}
    end
  end

  defp create_worker(name) do
    case Supervisor.start_child(name, []) do
      {:ok, pid} when is_pid(pid) -> pid
      _ -> raise "create_worker error"
    end
  end

end
