defmodule MemTest do
  use ExUnit.Case
  doctest Mem


  test "get and set" do
    assert is_nil(M.get(:a))

    M.set(:a, 1)
    assert 1 == M.get(:a)

    M.set(:a, 2)
    assert 2 == M.get(:a)
  end

  test "ttl" do
    M.set(:b, 2)
    assert is_nil(M.ttl(:b))

    M.set(:b, 3, 200)
    assert not is_nil(M.ttl(:b))
    assert 200 >= M.ttl(:b)

    M.set(:b, 4)
    assert is_nil(M.ttl(:b))
  end

  test "expire" do
    assert is_nil(M.expire(:c, 100))

    M.set(:c, 2)
    assert :ok = M.expire(:c, 100)

    M.set(:c, 3, 200)
    assert 100 < M.expire(:c, 100)
  end

  test "del" do
    assert :ok = M.del(:d)

    M.set(:d, 2)
    assert :ok = M.del(:d)
    assert is_nil(M.get(:d))

    M.set(:d, 2, 200)
    assert :ok = M.del(:d)
    assert is_nil(M.get(:d))
  end

end
