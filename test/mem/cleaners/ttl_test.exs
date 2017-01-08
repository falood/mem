defmodule Mem.Cleaners.TTLTest do
  use ExUnit.Case, async: true

  test "ttl" do
    value = String.duplicate("a", 1000)
    1..1000 |> Enum.each(&M.TTL.set(&1, value, 20))
    Mem.Utils.process_name(:out, M.TTL) |> send(:clean)
    :timer.sleep(2000)

    assert M.TTL.memory_used <= 3000
  end

end
