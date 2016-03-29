defmodule Mem.TTLCleanerTest do
  use ExUnit.Case, async: true

  test "ttl" do
    M.Expiry.set(:ttl, :value, 1)
    M.Expiry.set(:abc, :value)
    :timer.sleep(1100)
    Mem.Utils.process_name(:ttl, M.Expiry) |> send(:clean)
    :timer.sleep(1100)

    assert {:err, nil} = Mem.Utils.storage_name(:ttl, M.Expiry).get(:ttl)
    assert :value == M.Expiry.get(:abc)
  end

end
