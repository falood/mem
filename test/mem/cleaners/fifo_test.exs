defmodule Mem.Cleaners.FIFOTest do
  use ExUnit.Case, async: true

  test "fifo" do
    value = String.duplicate("a", 100)
    1..100 |> Enum.each(&M.FIFO.set(&1, value))
    :timer.sleep(2000)

    assert Mem.Utils.storage_name(:data, M.FIFO).memory_used <= 3000
  end

end
