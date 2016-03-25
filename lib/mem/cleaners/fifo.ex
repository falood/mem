defmodule Mem.Cleaners.FIFO do
  use GenEvent

  def handle_event({:set, key, _}, %{names: names}=state) do
    Mem.Cleaners.update_lru(names, key)
    Mem.Cleaners.check_memory(names, state.mem_size, self)
    {:ok, state}
  end

  def handle_event({:del, key}, %{names: names}=state) do
    Mem.Cleaners.delete_lru(names, key)
    {:ok, state}
  end

  def handle_event(:flush, %{names: names}=state) do
    Mem.Cleaners.flush(names)
    {:ok, state}
  end

  def handle_event({:hset, key, _, _}, %{names: names}=state) do
    case :ets.lookup(names.lru_ets, key) do
      [_] -> nil
      []  -> Mem.Cleaners.update_lru(names, key)
    end
    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  def handle_info(:clean, %{names: names, module: module}=state) do
    Mem.Cleaners.clean(names, module)
    Mem.Cleaners.check_memory(names, state.mem_size, self)
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  def terminate(:remove_handler, _), do: :ok
  def terminate(_, %{names: names} = state) do
    GenEvent.add_handler(names.event_name, __MODULE__, state)
  end

end
