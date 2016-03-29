defmodule Mem.Process.Worker do

  defmacro __using__(opts) do
    storages = opts |> Keyword.fetch!(:storages)

    quote do
      @data unquote(storages[:data])
      @ttl  unquote(storages[:ttl])

      use GenServer

      def start do
        GenServer.start(__MODULE__, [])
      end

      def init([]) do
        {:ok, []}
      end

      def handle_call({:insert, key, value, ttl}, _from, state) do
        is_nil(ttl) && @ttl.del(key) || @ttl.set(key, ttl)
        @data.set(key, value)
        {:reply, :ok, state}
      end

      def handle_call({:expire, key, nil}, _from, state) do
        @ttl.del(key)
        {:reply, :ok, state}
      end

      def handle_call({:expire, key, ttl}, _from, state) do
        @ttl.set(key, ttl)
        {:reply, :ok, state}
      end

      def handle_call({:delete, key}, _from, state) do
        @data.del(key)
        @ttl.del(key)
        {:reply, :ok, state}
      end

      def handle_call({:update, key, func}, _from, state) do
        reply =
          try do
            {:ok, value} = @data.get(key)
            @data.set(key, func.(value))
            func.(value)
            :ok
          rescue
            _ -> nil
          end
        {:reply, reply, state}
      end

    end

  end
end
