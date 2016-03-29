defmodule Mem.Cleaners.TTLTest do
  use ExUnit.Case, async: true

  test "ttl" do
    value = String.duplicate("a", 100)
    1..100 |> Enum.each(&M.TTL.set(&1, value, 20))
    :timer.sleep(2000)

    assert Mem.Utils.storage_name(:data, M.TTL).memory_used <= 3000
  end

end
