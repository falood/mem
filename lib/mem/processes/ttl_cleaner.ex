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
        interval = :timer.seconds(20)
        state =
          %{ ref: :"$end_of_table",
             interval: interval,
             number: 200,
           }
        Process.send_after(self(), :clean, interval)
        {:ok, state}
      end

      def handle_info(:clean, state) do
        {num, ref} =
          Enum.reduce(1..state.number, {0, state.ref}, fn
            _, {num, :"$end_of_table"} ->
              {num, @ttl.first}
            _, {num, ref} ->
              case do_clean(ref) do
                {:ok,  new_ref} -> {num + 1, new_ref}
                {:err, new_ref} -> {num,     new_ref}
              end
          end)
        if num + num < state.number do
          Process.send_after(self(), :clean, state.interval)
        else
          Process.send_after(self(), :clean, 100)
        end
        {:noreply, %{state | ref: ref}}
      end

      def handle_info(_, state) do
        {:noreply, state}
      end

      defp do_clean(key) do
        now = Mem.Utils.now()
        result =
          case @ttl.get(key) do
            {:ok, value} when value <= now ->
              @ttl.del(key)
              @data.del(key)
              is_nil(@storages[:out]) || @storages[:out].delete(key)
              :ok
            _ -> :err
          end

        try do
          {result, @ttl.next(key)}
        catch
          _, _ ->
            {result, @ttl.first}
        end
      end

    end
  end

end
