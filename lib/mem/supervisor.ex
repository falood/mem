defmodule Mem.Supervisor do
  use Supervisor

  def start_link(%{names: names, mem_size: mem_size, module: module}=args) do
    create_ets(names)
    try do
      Supervisor.start_link(__MODULE__, [names, module], name: names.sup_name)
    after
      is_nil(mem_size) || init_lru(args)
    end
  end

  def init([names, module]) do
    if Map.has_key?(names, :event_name) do
      [ worker(GenEvent, [[name: names.event_name]]) ]
    else [] end ++ [
      worker(Mem.Proxy, [names]),
      worker(Mem.TTLCleaner, [names, module]),
      supervisor(Mem.Worker.Supervisor, [names]),
    ] |> supervise(strategy: :one_for_all)
  end

  defp create_ets(names) do
    :ets.new(names.proxy_ets, [:set, :public, :named_table, :compressed, read_concurrency: true])
    :ets.new(names.data_ets,  [:set, :public, :named_table, :compressed, write_concurrency: true])
    :ets.new(names.ttl_ets,   [:set, :public, :named_table, :compressed, write_concurrency: true])
  end

  defp init_lru(%{names: names}=args) do
    :ets.new(names.lru_ets, [:set, :public, :named_table, :compressed])
    :ets.new(names.lru_inverted_ets, [:ordered_set, :public, :named_table, :compressed])
    cleaner =
      case args.mem_strategy do
        :lru  -> Mem.Cleaners.LRU
        :ttl  -> Mem.Cleaners.TTL
        :fifo -> Mem.Cleaners.FIFO
      end
    state = %{
      names: names,
      mem_size: args.mem_size,
      module: args.module,
    }
    GenEvent.add_handler(names.event_name, cleaner, state)
  end

end
