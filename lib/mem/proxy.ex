defmodule Mem.Proxy do
  defmacro __using__(opts) do
    storages      = opts |> Keyword.fetch!(:storages)
    processes     = opts |> Keyword.fetch!(:processes)
    worker_number = opts |> Keyword.fetch!(:worker_number)

    callbacks =
      if is_nil(processes[:lru]) do
        [ get: nil,
          ttl: nil,
        ]
      else
        [ get:    quote do unquote(processes[:lru]).callback(:get, key) end,
          ttl:    quote do unquote(processes[:lru]).callback(:ttl, key) end,
        ]
      end

    lru_memory_used_block =
      if is_nil(storages[:lru]) do
        0
      else
        quote do
          unquote(storages[:lru]).memory_used
        end
      end

    lru_flush_block =
      unless is_nil(storages[:lru]) do
        quote do
          unquote(storages[:lru]).flush
        end
      end

    quote do

      def memory_used do
        unquote(lru_memory_used_block) + unquote(storages[:data]).memory_used + unquote(storages[:ttl]).memory_used
      end

      def get(key) do
        ( with {:ok, ttl} <- unquote(storages[:ttl]).get(key),
               now        =  Mem.Utils.now,
               true       <- now > ttl,
          do: :expire
        ) |> case do
          :expire ->
            do_delete(key)
            {:err, nil}
          _       ->
            unquote(callbacks[:get])
            unquote(storages[:data]).get(key)
        end
      end

      def ttl(key) do
        now = Mem.Utils.now
        case unquote(storages[:ttl]).get(key) do
          {:err, nil} ->
            nil
          {:ok, ttl} when now > ttl ->
            do_delete(key)
            nil
          {:ok, ttl} ->
            unquote(callbacks[:ttl])
            ttl - now
        end
      end

      def set(key, value, ttl) do
        :ok = take_worker(key) |> GenServer.call({:insert, key, value, ttl})
      end

      def expire(key, ttl) when is_nil(ttl) or is_integer(ttl) do
        take_worker(key) |> GenServer.call({:expire, key, ttl})
      end

      def del(key) do
        :ok = do_delete(key)
      end

      def update(key, func, default) when is_function(func, 1) do
        take_worker(key) |> GenServer.call({:update, key, func, default})
      end

      def flush do
        unquote(storages[:data]).flush
        unquote(storages[:ttl]).flush
        unquote(lru_flush_block)
        :ok
      end

      defp do_delete(key) do
        take_worker(key) |> GenServer.call({:delete, key})
      end

      defp take_worker(key) do
        hash = :erlang.phash2(key, unquote(worker_number))
        unquote(storages[:proxy]).take_worker(hash) || unquote(processes[:proxy]).create_worker(hash)
      end

    end
  end

end
