defmodule Mem.Processes.Worker do

  defmacro __using__(opts) do
    storages  = opts |> Keyword.fetch!(:storages)
    out_cleaner = Mem.Utils.process_name(:out, opts[:name])

    callbacks =
      if is_nil(storages[:out]) do
        [ set: nil,
          del: nil,
          expire: nil,
          update: nil,
        ]
      else
        [ del:    quote do unquote(out_cleaner).callback(:del, key)         end,
          set:    quote do unquote(out_cleaner).callback(:set, key, ttl)    end,
          expire: quote do unquote(out_cleaner).callback(:expire, key, ttl) end,
          update: quote do unquote(out_cleaner).callback(:update, key)      end,
        ]
      end

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
        unquote(callbacks[:set])
        {:reply, :ok, state}
      end

      def handle_call({:expire, key, ttl}, _from, state) do
        if exist?(key) do
          is_nil(ttl) && @ttl.del(key) || @ttl.set(key, ttl)
          unquote(callbacks[:expire])
          {:reply, :ok, state}
        else
          do_delete(key)
          {:reply, nil, state}
        end
      end

      def handle_call({:delete, key}, _from, state) do
        do_delete(key)
        {:reply, :ok, state}
      end

      def handle_call({:update, key, func, default}, _from, state) do
        if exist?(key) do
          try do
            {:ok, value} = @data.get(key)
            @data.set(key, func.(value))
            unquote(callbacks[:update])
            {:reply, :ok, state}
          rescue
            _ ->
              {:reply, nil, state}
          end
        else
          ttl = nil
          @data.set(key, default)
          unquote(callbacks[:set])
          {:reply, :ok, state}
        end
      end

      defp exist?(key) do
        now = Mem.Utils.now
        case @data.get(key) do
          {:ok, _} ->
            case @ttl.get(key) do
              {:err, nil} ->
                true
              {:ok, ttl} when ttl >= now ->
                true
              _ ->
                false
            end
          _ ->
            false
        end
      end

      defp do_delete(key) do
        @data.del(key)
        @ttl.del(key)
        unquote(callbacks[:del])
      end


    end

  end
end
