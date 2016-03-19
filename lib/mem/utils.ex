defmodule Mem.Utils do
  def now do
    {i, j, k} = :erlang.timestamp
    i * 1_000_000_000_000 + j * 1_000_000 + k
  end
end
