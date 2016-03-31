defmodule Mem.Proxy do
  defmacro __using__(opts) do
    storages      = opts |> Keyword.fetch!(:storages)
    processes     = opts |> Keyword.fetch!(:processes)
    worker_number = opts |> Keyword.fetch!(:worker_number)

    callbacks =
      if is_nil(processes[:lru]) do
        [ get: nil,
          ttl: nil,
          set: nil,
          del: nil,
          expire: nil,
          update: nil,
        ]
      else
        [ get:    quote do unquote(processes[:lru]).callback(:get, key) end,
          ttl:    quote do unquote(processes[:lru]).callback(:ttl, key) end,
          del:    quote do unquote(processes[:lru]).callback(:del, key) end,
          update: quote do unquote(processes[:lru]).callback(:update, key) end,
          set:    quote do unquote(processes[:lru]).callback(:set, key, ttl) end,
          expire: quote do unquote(processes[:lru]).callback(:expire, key, ttl) end,
          update: quote do unquote(processes[:lru]).callback(:update, key) end,
        ]
      end

    lru_memory_used_block =
      if is_nil(storages[:lru]) do
        quote do
          unquote(storages[:lru]).memory_used
        end
      else
        0
      end

    quote do

      def memory_used do
        unquote(lru_memory_used_block) + unquote(storages[:data]).memory_used + unquote(storages[:ttl]).memory_used
      end

      def get(key) do
        ( with {:ok, ttl} <- unquote(storages[:ttl]).get(key),
               now = Mem.Utils.now,
               true <- now > ttl,
          do: :expire
        ) |> case do
          :expire ->
            do_delete(key)
            nil
          _       ->
            unquote(callbacks[:get])
            unquote(storages[:data]).get(key) |> elem(1)
        end
      end

      def ttl(key) do
        now = Mem.Utils.now
        ttl = unquote(storages[:ttl]).get(key) |> elem(1)
        cond do
          is_nil(ttl) ->
            nil
          now > ttl   ->
            do_delete(key)
            nil
          true        ->
            unquote(callbacks[:ttl])
            ttl - now
        end
      end

      def set(key, value, ttl) do
        take_worker(key) |> GenServer.call({:insert, key, value, ttl})
        unquote(callbacks[:set])
        :ok
      end

      def expire(key, ttl)
      when is_nil(ttl) or is_integer(ttl) do
        if exist?(key) do
          take_worker(key) |> GenServer.call({:expire, key, ttl})
          unquote(callbacks[:expire])
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
          unquote(callbacks[:update])
          take_worker(key) |> GenServer.call({:update, key, func})
        else
          ttl = nil
          unquote(callbacks[:set])
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
        case unquote(storages[:data]).get(key) do
          {:ok, _} ->
            case unquote(storages[:ttl]).get(key) do
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
        unquote(callbacks[:del])
      end

      defp take_worker(key) do
        hash = :erlang.phash2(key, unquote(worker_number))
        unquote(storages[:proxy]).take_worker(hash) || unquote(processes[:proxy]).create_worker(hash)
      end

    end
  end

end
