# Mem

> ETS based KV cache with TTL and LRU support

This project is under development, do **NOT** use it on production.

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
    Cache.set(:b, 2, 200)
    Cache.get(:a)
    Cache.expire(:a, 200)
    Cache.ttl(:a)
    Cache.del(:b)
    Cache.flush

    Cache.hset(:c, :a, 2)
    Cache.hget(:c, :a)
    ```
