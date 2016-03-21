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

  test "flush" do
    assert is_nil(M.get(:e))

    M.set(:e, 2)
    M.flush
    assert is_nil(M.get(:e))
  end

  test "hget and hset" do
    assert is_nil(M.get(:f))
    assert :ok = M.hset(:f, :a, 1)
    assert 1 = M.hget(:f, :a)
    assert %{a: 1} = M.get(:f)

    assert :ok = M.hset(:f, :b, 2)
    assert 2 = M.hget(:f, :b)
    assert %{a: 1, b: 2} = M.get(:f)

    M.set(:f, 1)
    assert is_nil(M.hset(:f, :a, 1))
    assert is_nil(M.hget(:f, :a))
  end

  test "inc" do
    assert is_nil(M.get(:g))
    M.set(:g, 1)
    assert :ok = M.inc(:g)
    assert 2 = M.get(:g)
    assert :ok = M.inc(:g, 1.1)
    assert 3.1 == M.get(:g)

    M.set(:g, 1.0)
    assert :ok = M.inc(:g, 2)
    assert 3.0 == M.get(:g)
    assert :ok = M.inc(:g, 1.1)
    assert 4.1 == M.get(:g)

    M.set(:g, :x)
    assert nil == M.inc(:g)
  end

end
