defmodule Mem.Cleaners do

  def update_lru(names, key) do
    inverted_key = {Mem.Utils.now, System.unique_integer}
    case :ets.lookup(names.lru_ets, key) do
      [] -> nil
      [{_, t}] ->
        :ets.delete(names.lru_inverted_ets, t)
    end
    :ets.insert(names.lru_ets, {key, inverted_key})
    :ets.insert(names.lru_inverted_ets, {inverted_key, key})
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
    :ets.delete_all_objects(names.lru_inverted_ets)
    :ets.delete_all_objects(names.lru_ets)
    :ok
  end

  def check_memory(names, mem_size, pid) do
    if :ets.info(names.data_ets, :memory) > mem_size do
      send(pid, {:lru, :clean})
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
