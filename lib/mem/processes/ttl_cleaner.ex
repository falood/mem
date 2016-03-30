defmodule Mem.Processes.TTLCleaner do

  defmacro __using__(opts) do
    storages = opts |> Keyword.fetch!(:storages)

    quote do
      @storages unquote(storages)
      @ttl      @storages[:ttl]
      @data     @storages[:data]

      use GenServer

      def start_link do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      def init([]) do
        interval = :timer.seconds(60) # 1 min
        state =
          %{ ref: :"$end_of_table",
             interval: interval,
             number: 20,
           }
        Process.send_after(self, :clean, interval)
        {:ok, state}
      end

      def handle_info(:clean, state) do
        ref =
          Enum.reduce(1..state.number, state.ref, fn(_, acc) ->
            do_clean(acc)
          end)

        Process.send_after(self, :clean, state.interval)
        {:noreply, %{state | ref: ref}}
      end

      def handle_info(_, state) do
        {:noreply, state}
      end

      defp do_clean(:"$end_of_table") do
        @ttl.first
      end

      defp do_clean(key) do
        @ttl.del(key)
        @data.del(key)
        is_nil(@storages[:lru]) || @storages[:lru].delete(key)
        try do
          @ttl.next(key)
        catch
          _, _ ->
            @ttl.first
        end
      end

    end
  end

end
