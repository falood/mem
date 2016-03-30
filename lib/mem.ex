defmodule Mem do
  defmacro __using__(opts) do
    worker_number      = opts |> Keyword.get(:worker_number, 2)
    default_ttl        = opts |> Keyword.get(:default_ttl, nil)
    maxmemory_size     = opts |> Keyword.get(:maxmemory_size, nil)
    maxmemory_strategy = opts |> Keyword.get(:maxmemory_strategy, :lru)
    persistence        = opts |> Keyword.get(:persistence, false)
    maxmemory_strategy in [:lru, :ttl, :fifo] || raise "unknown maxmemory strategy"

    quote do
      opts = Application.get_env(:mem, __MODULE__, [])
      @worker_number unquote(worker_number)      || opts[:worker_number]      || 2
      @default_ttl   unquote(default_ttl)        || opts[:default_ttl]        || nil
      @opts_mem_size unquote(maxmemory_size)     || opts[:maxmemory_size]     || nil
      @mem_strategy  unquote(maxmemory_strategy) || opts[:maxmemory_strategy] || :lru
      @mem_size      Mem.Utils.format_space_size(@opts_mem_size)
      @persistence   unquote(persistence)

      @storages [
        proxy: Mem.Builder.create_proxy_storage_module(__MODULE__, __ENV__),
        data:  Mem.Builder.create_data_storage_module(@persistence, __MODULE__, __ENV__),
        ttl:   Mem.Builder.create_ttl_storage_module(@persistence, __MODULE__, __ENV__),
      ]

      @processes [
        proxy: Mem.Builder.create_proxy_process_module(__MODULE__, __ENV__),
        ttl:   Mem.Builder.create_ttl_process_module(@storages, __MODULE__, __ENV__),
      ]

      unless is_nil(@mem_size) do
        @storages put_in(@storages, [:lru], Mem.Builder.create_lru_storage_module(
              @persistence, __MODULE__, __ENV__
        ))
        @processes put_in(@processes, [:lru], Mem.Builder.create_lru_process_module(
            @storages, @mem_size, @mem_strategy, __MODULE__, __ENV__
        ))
      end

      Mem.Builder.create_worker_process_module(@storages, __MODULE__, __ENV__)

      @proxy Mem.Builder.create_proxy_module(
        @storages, @processes, @worker_number, __MODULE__, __ENV__
      )

      @sup Mem.Builder.create_supervisor_module(
        @storages, @processes, __MODULE__, __ENV__
      )

      def child_spec do
        if @persistence do
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
        set(key, value, @default_ttl)
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
          value when is_map(value) -> Map.get(value, field)
          _ -> nil
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
