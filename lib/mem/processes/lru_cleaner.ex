defmodule Mem.Process.LRUCleaner do

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

      use GenServer
      use unquote(strategy_module)

      def start_link do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      def init([]) do
        {:ok, []}
      end

      def handle_cast({:update, key, time}, state) do
        @lru.update(key, time)
        {:noreply, state}
      end

      def handle_cast({:delete, key}, state) do
        @lru.delete(key)
        {:noreply, state}
      end

      def handle_cast(:flush, state) do
        @lru.flush
        {:noreply, state}
      end

      def handle_info(:clean, state) do
        with true <- @data.memory > @mem_size,
             :ok  <- do_clean,
        do:  Process.send_after(self, :clean)
        {:noreply, state}
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

    end
  end

end
