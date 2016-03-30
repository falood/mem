defmodule Mem.Proxy do
  defmacro __using__(opts) do
    storages = opts |> Keyword.fetch!(:storages)
    processes = opts |> Keyword.fetch!(:processes)
    worker_number = opts |> Keyword.fetch!(:worker_number)

    quote do
      @worker_number unquote(worker_number)
      @storages      unquote(storages)
      @processes     unquote(processes)

      def memory_used do
        ( is_nil(@storages[:lru]) && 0 || @storages[:lru].memory_used
        ) + @storages[:data].memory_used + @storages[:ttl].memory_used
      end

      def get(key) do
        ( with {:ok, ttl} <- @storages[:ttl].get(key),
               now = Mem.Utils.now,
               true <- now > ttl,
          do: :expire
        ) |> case do
          :expire ->
            do_delete(key)
            nil
          _       ->
            is_nil(@processes[:lru]) || @processes[:lru].callback(:get, key)
            @storages[:data].get(key) |> elem(1)
        end
      end

      def ttl(key) do
        now = Mem.Utils.now
        ttl = @storages[:ttl].get(key) |> elem(1)
        cond do
          is_nil(ttl) ->
            nil
          now > ttl   ->
            do_delete(key)
            nil
          true        ->
            is_nil(@processes[:lru]) || @processes[:lru].callback(:ttl, key)
            ttl - now
        end
      end

      def set(key, value, ttl) do
        take_worker(key) |> GenServer.call({:insert, key, value, ttl})
        is_nil(@processes[:lru]) || @processes[:lru].callback(:set, key, ttl)
        :ok
      end

      def expire(key, ttl)
      when is_nil(ttl) or is_integer(ttl) do
        if exist?(key) do
          take_worker(key) |> GenServer.call({:expire, key, ttl})
          is_nil(@processes[:lru]) || @processes[:lru].callback(:expire, key, ttl)
          :ok
        else
          nil
        end
      end

      def del(key) do
        do_delete(key)
        :ok
      end

      def update(key, func, default) when is_function(func, 1) do
        if exist?(key) do
          is_nil(@processes[:lru]) || @processes[:lru].callback(:update, key)
          take_worker(key) |> GenServer.call({:update, key, func})
        else
          is_nil(@processes[:lru]) || @processes[:lru].callback(:set, key, nil)
          take_worker(key) |> GenServer.call({:insert, key, default, nil})
        end
      end

      def flush do
        for {_, module} <- unquote(Keyword.drop(storages, [:proxy])) do
          module.flush
        end
        :ok
      end

      defp exist?(key) do
        now = Mem.Utils.now
        case @storages[:data].get(key) do
          {:ok, _} ->
            case @storages[:ttl].get(key) do
              {:err, nil} ->
                true
              {:ok, ttl} when ttl >= now ->
                true
              _ ->
                do_delete(key)
                false
            end
          _ ->
            false
        end
      end

      defp do_delete(key) do
        take_worker(key) |> GenServer.call({:delete, key})
        is_nil(@processes[:lru]) || @processes[:lru].callback(:del, key)
      end

      defp take_worker(key) do
        hash = :erlang.phash2(key, @worker_number)
        @storages[:proxy].take_worker(hash) || @processes[:proxy].create_worker(hash)
      end

    end
  end

end
