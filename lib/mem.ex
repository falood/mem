defmodule Mem do
  defmacro __using__(opts) do
    config = Application.get_env(:mem, __MODULE__, [])
    worker_number      = opts |> Keyword.get(:worker_number, nil)       || config[:worker_number]      || 2
    default_ttl        = opts |> Keyword.get(:default_ttl, nil)         || config[:default_ttl]        || nil
    maxmemory_size     = opts |> Keyword.get(:maxmemory_size, nil)      || config[:maxmemory_size]     || nil
    maxmemory_strategy = opts |> Keyword.get(:maxmemory_strategy, :lru) || config[:maxmemory_strategy] || :lru
    persistence        = opts |> Keyword.get(:persistence, false)       || config[:persistence]        || false
    maxmemory_strategy in [:lru, :ttl, :fifo] || raise "unknown maxmemory strategy"

    quote do
      "Elixir." <> name = __MODULE__ |> to_string
      @opts [
        worker_number: unquote(worker_number),
        default_ttl:   unquote(default_ttl),
        mem_size:      unquote(Mem.Utils.format_space_size(maxmemory_size)),
        mem_strategy:  unquote(maxmemory_strategy),
        persistence:   unquote(persistence),
        name:          name,
        env:           __ENV__,
      ]

      Code.compiler_options(ignore_module_conflict: true)
      @storages Mem.Builder.create_storages(@opts)
      @opts [{:storages, @storages} | @opts]

      @processes Mem.Builder.create_processes(@opts)
      @opts [{:processes, @processes} | @opts]

      @proxy Mem.Builder.create_proxy(@opts)
      @sup Mem.Builder.create_supervisor(@opts)
      Code.compiler_options(ignore_module_conflict: false)

      def child_spec do
        if unquote(persistence) do
          Application.start(:mnesia)
          :mnesia.create_schema([node])
          :mnesia.change_table_copy_type(:schema, node, :disc_copies)
        end
        Supervisor.Spec.supervisor(@sup, [], id: __MODULE__)
      end

      def memory_used do
        @proxy.memory_used
      end

      def get(key) do
        @proxy.get(key)
      end

      def set(key, value) do
        set(key, value, unquote(default_ttl))
      end

      def set(key, value, nil) do
        @proxy.set(key, value, nil)
      end

      def set(key, value, ttl) do
        ttl = Mem.Utils.now + ttl * 1000_000
        @proxy.set(key, value, ttl)
      end

      def ttl(key) do
        case @proxy.ttl(key) do
          ttl when is_integer(ttl) -> round(ttl / 1_000_000)
          nil                      -> nil
        end
      end

      def expire(key) do
        @proxy.expire(key, nil)
      end

      def expire(key, ttl) when is_integer(ttl) do
        ttl = Mem.Utils.now + ttl * 1000_000
        @proxy.expire(key, ttl)
      end

      def del(key) do
        @proxy.del(key)
      end

      def flush do
        @proxy.flush
      end

      def hget(key, field) do
        case @proxy.get(key) do
          {:ok, value} when is_map(value) ->
            {:ok, Map.get(value, field)}
          _ -> {:err, nil}
        end
      end

      def hset(key, field, value) do
        func = fn m -> put_in(m, [field], value) end
        @proxy.update(key, func, %{field => value})
      end

      def inc(key, value \\ 1) do
        func = fn m -> m + value end
        @proxy.update(key, func, value)
      end

    end
  end
end
