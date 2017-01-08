defmodule Mem.Cleaners.FIFOTest do
  use ExUnit.Case, async: true

  test "fifo" do
    value = String.duplicate("a", 1000)
    1..1000 |> Enum.each(&M.FIFO.set(&1, value))
    Mem.Utils.process_name(:out, M.FIFO) |> send(:clean)
    :timer.sleep(2000)

    assert M.FIFO.memory_used <= 3000
  end

end
