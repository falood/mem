defmodule Mem.Processes.LRUCleaner do
  defmacro __using__(opts) do
    storages        = opts |> Keyword.fetch!(:storages)
    mem_size        = opts |> Keyword.fetch!(:mem_size)
    mem_strategy    = opts |> Keyword.fetch!(:mem_strategy)
    strategy_module =
      case mem_strategy do
        :lru  -> Mem.Cleaners.LRU
        :ttl  -> Mem.Cleaners.TTL
        :fifo -> Mem.Cleaners.FIFO
        _     -> raise "unknow max memory strategy"
      end

    quote do
      @mem_size unquote(mem_size)
      @storages unquote(storages)
      @lru      @storages[:lru]
      @ttl      @storages[:ttl]
      @data     @storages[:data]
      @interval :timer.seconds(10)

      use GenServer
      use unquote(strategy_module)

      def start_link do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      def init([]) do
        Process.send_after(self, :clean, @interval)
        {:ok, [], :hibernate}
      end

      def handle_info(:clean, state) do
        memory_used = @data.memory_used + @ttl.memory_used + @lru.memory_used
        ( with true <- memory_used > @mem_size,
               :ok  <- do_clean,
          do: :clean
        ) |> case do
          :clean -> send(self, :clean)
          _      -> Process.send_after(self, :clean, @interval)
        end
        {:noreply, state, :hibernate}
      end

      def handle_info(_, state) do
        {:noreply, state}
      end

      defp do_clean do
        case @lru.drop_first do
          nil -> nil
          key ->
            @data.del(key)
            @ttl.del(key)
            :ok
        end
      end

      defp do_update(key, time) do
        @lru.update(key, time)
      end

      defp do_delete(key) do
        @lru.delete(key)
      end

    end
  end

end
