# Mem

> KV cache with TTL, Replacement and Persistence support

[![Build Status](https://img.shields.io/travis/falood/mem.svg?style=flat-square)](https://travis-ci.org/falood/mem)
[![Hex.pm Version](https://img.shields.io/hexpm/v/mem.svg?style=flat-square)](https://hex.pm/packages/mem)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dt/mem.svg?style=flat-square)](https://hex.pm/packages/mem)
## Usage

1. define your cache module
    ```elixir
    defmodule Cache do
      use Mem,
        worker_number:      2,       # (optional, default: 2) how many processes in worker pool
        default_ttl:        300,     # (optional, default: nil) default seconds for set/2

        maxmemory_size:     "1000M", # (optional, default: nil) max memory used, support such format: [1000, "10k", "1GB", "1000 K"]
        maxmemory_strategy: :lru,    # ([:lru, :ttl, :fifo]) strategy for cleaning memory
        persistence:        false    # (optional, default: false) whether enable persistence

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

## Thanks

* [redink](https://github.com/redink)
