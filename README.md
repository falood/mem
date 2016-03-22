# Mem

> ETS based KV cache with TTL and LRU support

[![Build Status](https://img.shields.io/travis/falood/mem.svg?style=flat-square)](https://travis-ci.org/falood/mem)
[![Hex.pm Version](https://img.shields.io/hexpm/v/mem.svg?style=flat-square)](https://hex.pm/packages/mem)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dt/mem.svg?style=flat-square)](https://hex.pm/packages/mem)
## Usage

1. define your cache module
    ```elixir
    defmodule Cache do
      use Mem
    end
    ```

2. add this module to supervisor
    ```elixir
    defmodule MyApp.Supervisor do
      use Supervisor

      def start_link do
        Supervisor.start_link(__MODULE__, [])
      end

      def init([]) do
        [ Cache.child_spec,
        ] |> supervise(strategy: :one_for_one)
      end

    end
    ```

3. just use it like redis
    ```elixir
    Cache.set(:a, 1)
    Cache.inc(:a, 2)
    Cache.set(:b, 2, 200)
    Cache.get(:a)
    Cache.expire(:a, 200)
    Cache.ttl(:a)
    Cache.del(:b)
    Cache.flush

    Cache.hset(:c, :a, 2)
    Cache.hget(:c, :a)
    ```
