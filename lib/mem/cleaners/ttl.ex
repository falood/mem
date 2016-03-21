defmodule Mem.Cleaners.TTL do
  use GenEvent

  def handle_event({:expire, key}, %{names: names}=state) do
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

end
