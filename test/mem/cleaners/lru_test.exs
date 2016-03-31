defmodule Mem.Cleaners.LRUTest do
  use ExUnit.Case, async: true

  test "lru" do
    value = String.duplicate("a", 1000)
    1..1000 |> Enum.each(&M.LRU.set(&1, value))
    Mem.Utils.process_name(:lru, M.LRU) |> send(:clean)
    :timer.sleep(2000)

    assert M.LRU.memory_used <= 3000
  end

end
