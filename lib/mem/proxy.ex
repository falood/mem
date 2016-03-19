defmodule Mem.Proxy do
  use GenServer

  def get(names, hash, key) do
    ( with {:ok, ttl} <- lookup(names[:expiry_ets], key),
           {i, j, k} = :erlang.timestamp,
           now = i * 1_000_000_000_000 + j * 1_000_000 + k,
           true <- now > ttl,
      do: :expire
    ) |> case do
      :expire ->
        take_worker(names, hash) |> GenServer.cast({:delete, names, key})
        nil
      _       ->
        lookup(names[:data_ets], key) |> elem(1)
    end
  end

  def ttl(names, hash, key) do
    {i, j, k} = :erlang.timestamp
    now = i * 1_000_000_000_000 + j * 1_000_000 + k
    ttl = lookup(names[:expiry_ets], key) |> elem(1)
    cond do
      is_nil(ttl) ->
        nil
      now > ttl   ->
        take_worker(names, hash) |> GenServer.cast({:delete, names, key})
        nil
      true        ->
        ttl - now
    end
  end

  defp lookup(tab, key) do
    case :ets.lookup(tab, key) do
      [{^key, value}] -> {:ok, value}
      []              -> {:err, nil}
    end
  end

  def set(names, hash, key, value, ttl)
  when is_nil(ttl) or is_integer(ttl) do
    take_worker(names, hash) |> GenServer.cast({:insert, names, key, value, ttl})
    :ok
  end

  def expire(names, hash, key, ttl)
  when is_nil(ttl) or is_integer(ttl) do
    take_worker(names, hash) |> GenServer.cast({:expire, names, key, ttl})
    :ok
  end

  def del(names, hash, key) do
    take_worker(names, hash) |> GenServer.cast({:delete, names, key})
    :ok
  end

  defp take_worker(names, hash) do
    GenServer.call(names[:proxy_name], {:take_workers, hash})
  end

  def start_link(names) do
    GenServer.start_link(__MODULE__, names, name: names[:proxy_name])
  end

  def init(names) do
    state =
      %{ workers: %{},
         names: names,
       }
    {:ok, state}
  end

  def handle_call({:take_workers, hash}, _from,
    %{workers: workers, names: names} = state
  ) do
    pid =
      ( with pid when is_pid(pid) <- workers[hash],
             true <- Process.alive?(pid),
        do: {:ok, pid}
      ) |> case do
        {:ok, pid} -> pid
        _          -> create_worker(names[:worker_sup_name])
      end
    workers = put_in(workers, [hash], pid)
    {:reply, pid, %{state | workers: workers}}
  end

  defp create_worker(name) do
    case Supervisor.start_child(name, []) do
      {:ok, pid} when is_pid(pid) -> pid
      _ -> raise "create_worker error"
    end
  end

end
