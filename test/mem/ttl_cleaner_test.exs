defmodule Mem.TTLCleanerTest do
  use ExUnit.Case, async: true

  test "ttl" do
    M.Expiry.set(:ttl, :value, 1)
    M.Expiry.set(:ttl2, :value, 100)
    M.Expiry.set(:abc, :value)
    :timer.sleep(1100)
    Mem.Utils.process_name(:ttl, M.Expiry) |> send(:clean)
    :timer.sleep(1100)

    assert {:err, nil} = Mem.Utils.storage_name(:ttl, M.Expiry).get(:ttl)
    assert {:ok, _} = Mem.Utils.storage_name(:ttl, M.Expiry).get(:ttl2)

    assert {:ok, :value} == M.Expiry.get(:abc)
    assert {:ok, :value} == M.Expiry.get(:ttl2)
  end

end
