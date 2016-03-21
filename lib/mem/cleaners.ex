defmodule Mem.Cleaners do

  def update_lru(names, key) do
    now = Mem.Utils.now
    case :ets.lookup(names.lru_ets, key) do
      [] -> nil
      [{_, t}] ->
        :ets.delete(names.lru_inverted_ets, t)
    end
    :ets.insert(names.lru_ets, {key, now})
    :ets.insert(names.lru_inverted_ets, {now, key})
  end

  def delete_lru(names, key) do
    case :ets.lookup(names.lru_ets, key) do
      [] -> nil
      [{_, t}] ->
        :ets.delete(names.lru_inverted_ets, t)
        :ets.delete(names.lru_ets, key)
    end
  end

  def flush(names) do
    do_flush
    :ets.delete_all_objects(names.lru_inverted_ets)
    :ets.delete_all_objects(names.lru_ets)
    :ok
  end

  defp do_flush do
    receive do
      _ -> do_flush
    after
      0 -> :ok
    end
  end

  def check_memory(names, mem_size, pid) do
    if :ets.info(names.data_ets, :memory) > mem_size do
      send(pid, :clean)
    end
  end

  def clean(names, module) do
    case :ets.first(names.lru_inverted_ets) do
      :"$end_of_table" ->
        :timer.sleep(2000)
      t ->
        [{_, key}] = :ets.lookup(names.lru_inverted_ets, t)
        module.del(key)
    end
  end

end
