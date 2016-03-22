defmodule Mem.TTLCleanerTest do
  use ExUnit.Case, async: true

  test "ttl" do
    M.Expiry.set(:ttl, :value, 1)
    M.Expiry.set(:abc, :value)
    :timer.sleep(1100)
    GenServer.whereis(:"Mem.M.Expiry.TTLCleaner") |> send(:clean)
    :timer.sleep(1100)

    assert [] = :ets.lookup(:"Mem.Data.M.Expiry", :ttl)
    assert :value == M.Expiry.get(:abc)
  end

end
