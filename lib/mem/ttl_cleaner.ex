defmodule Mem.TTLCleaner do
  use GenServer

  def start_link(names, module) do
    GenServer.start_link(__MODULE__, [names, module], name: names.ttl_cleaner_name)
  end

  def init([names, module]) do
    interval = :timer.seconds(60) # 1 min
    state =
      %{ ref: :"$end_of_table",
         interval: interval,
         number: 20,
         names: names,
         module: module,
       }
    Process.send_after(self, :clean, interval)
    {:ok, state}
  end

  def handle_info(:clean, state) do
    ref =
      Enum.reduce(1..state.number, state.ref, fn(_, acc) ->
        do_clean(state.names, state.module, acc)
      end)

    Process.send_after(self, :clean, state.interval)
    {:noreply, %{state | ref: ref}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp do_clean(names, _, :"$end_of_table") do
    :ets.first(names.ttl_ets)
  end

  defp do_clean(names, module, key) do
    module.ttl(key)
    :ets.next(names.ttl_ets, key)
  end

end
