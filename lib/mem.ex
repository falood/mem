defmodule Mem do
  defmacro __using__(opts) do
    worker_number      = opts |> Keyword.get(:worker_number, 2)
    default_ttl        = opts |> Keyword.get(:default_ttl, nil)
    maxmemory_size     = opts |> Keyword.get(:maxmemory_size, nil) |> Mem.Utils.format_space_size
    maxmemory_strategy = opts |> Keyword.get(:maxmemory_strategy, :lru)
    maxmemory_strategy in [:lru, :ttl, :fifo] || raise "unknown maxmemory strategy"

    quote do
      @worker_number unquote(worker_number)
      @default_ttl   unquote(default_ttl)
      @mem_size      unquote(maxmemory_size)
      @mem_strategy  unquote(maxmemory_strategy)
      "Elixir." <> name = __MODULE__ |> to_string
      @names %{
        proxy_ets:        :"Mem.Proxy.#{name}",
        data_ets:         :"Mem.Data.#{name}",
        ttl_ets:          :"Mem.TTL.#{name}",
        sup_name:         :"Mem.#{name}",
        proxy_name:       :"Mem.#{name}.Proxy",
        ttl_cleaner_name: :"Mem.#{name}.TTLCleaner",
        worker_sup_name:  :"Mem.#{name}.Supervisor",
      }

      unless is_nil(@mem_size) do
        @names Map.merge(@names, %{
          lru_ets:          :"Mem.LRU.#{name}",
          lru_inverted_ets: :"Mem.LRU.Inverted.#{name}",
          lru_cleaner_name: :"Mem.#{name}.LRUCleaner",
          event_name:       :"Mem.#{name}.Event",
        })
      end

      def child_spec do
        Supervisor.Spec.supervisor(
          Mem.Supervisor,
          [{@names, @mem_size, @mem_strategy, __MODULE__}],
          id: __MODULE__
        )
      end

      def get(key) do
        Mem.Proxy.get(@names, phash(key), key)
      end

      def set(key, value) do
        set(key, value, @default_ttl)
      end

      def set(key, value, nil) do
        Mem.Proxy.set(@names, phash(key), key, value, nil)
      end

      def set(key, value, ttl) do
        ttl = ttl * 1000_000
        Mem.Proxy.set(@names, phash(key), key, value, ttl)
      end

      def ttl(key) do
        case Mem.Proxy.ttl(@names, phash(key), key) do
          ttl when is_integer(ttl) -> round(ttl / 1_000_000)
          nil                      -> nil
        end
      end

      def expire(key, ttl) do
        Mem.Proxy.expire(@names, phash(key), key, ttl)
      end

      def del(key) do
        Mem.Proxy.del(@names, phash(key), key)
      end

      def flush do
        Mem.Proxy.flush(@names)
      end

      defp phash(key) do
        :erlang.phash2(key, @worker_number)
      end

    end
  end
end
